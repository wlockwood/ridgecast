# Co-channel interference scenarios

Use MCP `start_interference_scenario` to evaluate a desired link with up to 64 named co-channel transmitters. The job uses the selected CPU propagation model, receiver configuration, feed losses, and horizontal/elevation antenna gains for every path. It snapshots those inputs before starting; poll `job_status` and cancel with `cancel_job`. The ordinary `evaluate_link` response and default coverage/analysis results retain their existing SNR meaning.

Example request:

```json
{
  "session_id": "SESSION",
  "from": {"node": "Desired site"},
  "to": {"node": "Receiver"},
  "frequency_mhz": 915,
  "background_policy": "modeled_without_occupancy",
  "interferers": [
    {"node": "Neighbor site", "overlap_fraction": 0.5}
  ]
}
```

Endpoint syntax follows [MCP endpoint parameters](mcp-server.md). Each interferer names an authored network node and supplies a simultaneous overlap fraction from 0 to 1. This fraction multiplies received linear power; it is an explicit scenario assumption, not a prediction of traffic or a spectral adjacent-channel rejection model. A zero fraction contributes zero power and requires no propagation work. Positive-overlap paths with missing terrain produce unknown contributions and an unavailable aggregate SINR when the background excludes those sources.

Choose one explicit background policy:

| Value | Meaning |
| --- | --- |
| `modeled_without_occupancy` | Recalculate the receiver/incidental man-made background with the aggregate shared-band occupancy prior disabled and measurements excluded, then add named sources. |
| `selected_floor_excludes_interferers` | Use the normally selected floor and add named sources. You attest that the selected measurement or modeled floor excludes them. |
| `selected_floor_includes_interferers` | Use a selected floor that already contains these sources. Report their individual powers without adding them again. |

The result separates the desired received level, selected background, each source's received and overlap-adjusted power, original link SNR, and scenario SINR. For the first two policies, `SINR = desired − 10 log10(background_linear + sum(overlap × interferer_linear))`. For the third policy, SINR uses the selected background directly to avoid counting a measured interferer twice. Unknown source paths remain visible even when a measured floor already includes them.

An interfering transmitter does not need a noise measurement for its predicted power at the receiver. Its propagation path and antenna response determine that power; the scenario receiver's selected background supplies the noise term. Requested unavailable atmospheric inputs still prevent a modeled desired background from being reported as complete, while compatible measured totals retain precedence.

SINR describes the desired transmitter's signal at the scenario receiver. Missing noise information at the desired transmitter's unused reverse receiver does not invalidate that forward calculation. When the strict two-way noise report is unavailable, `legacy_link` is `null` and `legacy_link_unavailable_reason` explains why; `scenario.legacy_snr_db` still reports the valid forward selected-floor SNR. If both receiver references are known, the complete legacy link report is retained unchanged. Missing required RF path data or an incomplete background at the actual scenario receiver still prevents a valid scenario result.

These are bounded planning scenarios. They do not predict adjacent-channel interference, front-end overload, intermodulation, scheduling, receiver capture, or packet delivery probability. The result records the authored scenario and settings; it does not silently reinterpret existing fade margins as SINR.
