# Drive RidgeCast from an AI assistant

RidgeCast ships an [MCP](https://modelcontextprotocol.io) server, `ridgecast-mcp`,
that exposes the terrain, propagation and network-planning engine to an AI
assistant. The assistant can then answer questions such as where to put a node,
whether two sites can communicate, or what signal an address would receive.

The server runs headless: no window, no map, and no event loop. It shares the
same terrain, land-cover and population caches as the desktop application, so
data downloaded in one is reused by the other.

This guide assumes you are comfortable with RidgeCast's own concepts. If a term
here is unfamiliar, start with the [glossary](../glossary.md). For the complete
tool list and every argument, see the [MCP server reference](../reference/mcp-server.md).

---

## Register a packaged server

The Windows release ZIP includes `ridgecast-mcp.exe` alongside the desktop
executable. Extract the entire directory, then configure your assistant's MCP
client with an absolute executable path. For example, a client accepting the
common JSON configuration shape can use:

```json
{
  "mcpServers": {
    "ridgecast": {
      "command": "C:\\Users\\you\\Apps\\RidgeCast\\ridgecast-mcp.exe",
      "args": [
        "--offline",
        "--limitation-log",
        "C:\\Users\\you\\Documents\\RidgeCast\\mcp-limitations.md"
      ]
    }
  }
}
```

Create the writable log directory first and substitute your actual paths.
JSON uses doubled backslashes; paths with spaces remain a single string and do
not need embedded quotes. Omit `--offline` to permit normal downloads. The
default cache root is shared with the desktop; supply `--cache-dir` and an
absolute writable path to choose a separate root. No source checkout or running
desktop session is needed. Check available options with:

```powershell
& 'C:\Users\you\Apps\RidgeCast\ridgecast-mcp.exe' --help
```

Use your client's executable registration workflow for this packaged command.
The source-based `cargo` instructions below remain available for developers.

## What it can and cannot do

The server covers a deliberate subset of the application:

| Available | Not available |
| --- | --- |
| Open, create, merge and save networks | Image export to PNG or animated GIF |
| Add, edit and remove nodes | LiDAR tile staging and selection |
| Terrain, land cover and population at a point | Geocoding anything but a US street address |
| Terrain profiles between two points | |
| Full link budgets, both directions | |
| Signal strength at an arbitrary point | |
| Solving a network's links (`solve_links`) | |
| Reachability, critical sites, routes, N-1 failure sweeps, throughput | |
| Coverage maps, by area and population | |
| Coverage export to KML, KMZ, GeoJSON, GeoTIFF, CSV | |
| Antenna height solving | |
| Candidate site search over an area | |
| Repeater chain proposals | |
| FCC amateur data queries and lookup | |
| Shared system profile creation and editing | |
| Radio Mobile network import | |

Ask the assistant to call `server_capabilities`; it reports the current lists
rather than these, which may age.

For a question that needs an unavailable capability, use the desktop application.

Two things are worth knowing before you start:

- **Links are calculated results that can be saved.** Opening a network restores
  any directed links in its file; a new network has none. Resilience and routing
  analyses need those results, and saved links may reflect older assumptions.
  Ask the assistant to solve links when they are absent or the radio inputs or
  model settings have changed.
- **For one place, ask about that place.** Signal at a single address is seconds
  of work. A coverage map over an area is minutes. Both are available, so say
  which question you mean.

## Build and register the server

Build it once:

```bash
cargo build --release --package ridgecast-mcp
```

The repository includes an `.mcp.json` that registers the server for MCP clients
started in the project directory, so a client launched there finds it with no
further configuration.

To register it manually with Claude Code:

```bash
claude mcp add ridgecast -- cargo run --quiet --release --package ridgecast-mcp --
```

Confirm it starts:

```bash
./target/release/ridgecast-mcp --help
```

### Options

| Option | Effect |
| --- | --- |
| `--cache-dir <PATH>` | Cache root. Defaults to the desktop application's, sharing downloads. |
| `--offline` | Never download. Uncached data is reported unavailable rather than guessed. |
| `--gpu` | Use GPU acceleration where the propagation model allows it. |
| `--limitation-log <PATH>` | Where gap reports are appended. Defaults to `docs/review/mcp-limitations.md`. |

The server speaks the protocol on standard input and output; diagnostics go to
standard error.

## Ask for something

With the server registered, ask in plain language. The bundled `ridgecast`
skill teaches the assistant how to sequence the tools, so these work directly:

- *"How much coverage can someone expect at 123 Brick Road with MapleMesh.json?"*
- *"Find the best spot for a node within 3 km of 47.3915, -122.0357."*
- *"Can my site at 47.48, -121.99 reach 47.39, -122.04?"*
- *"Excluding forest, propose a repeater chain between these two nodes."*

### Name a file, always

The server never loads a network on its own. A request about "our network" fails
until you name a file. Give a path the first time:

> Looking at `networks/MapleMesh network.json`, how should we extend coverage
> toward Maple Valley?

### Locations

RidgeCast geocodes US street addresses. Everything else — a city, a business, a
park, a landmark — the assistant resolves itself, from its own sources.

That split is deliberate. A point-of-interest geocoder inside RidgeCast would be
another outbound service to cache and document, doing a job the assistant is better
placed to do: it can show you the coordinates it picked and ask whether they are
right, which a library call cannot.

What you should expect, and can hold it to:

- It tells you where a coordinate came from, rather than reporting results about an
  unnamed point.
- It asks you to confirm before starting anything that takes minutes.
- It never quietly substitutes a nearby guess. A plausible wrong coordinate is the
  worst outcome here, because every prediction after it is confidently about the
  wrong place and nothing in the output shows it.

Supply coordinates directly when you have them; that removes the ambiguity
entirely.

### Say what radio you mean

Predictions depend on the antenna height, transmit power and gain assumed. The
defaults are a modest 1.5 m handheld, chosen because an optimistic default would
overstate coverage. If you are planning around a mast, say so:

> …at 47.39, -122.04 with a 20 m antenna.

Every result states the assumptions it used. Read them.

## Expect long operations to take minutes

Site scans and chain searches return a job handle and run in the background. The
assistant polls it.

Terrain downloads happen first. For an area RidgeCast has not seen, that can be
hundreds of tiles, so ask the assistant to check readiness before committing:

> Before scanning, tell me how much terrain that would download.

Scan cost is dominated by candidate spacing: halving it roughly quadruples the
work. Start at 200 m or coarser, then refine the promising part.

You can stop a running job at any time — ask the assistant to cancel it.

## Editing and saving

Edits change the server's memory only. Nothing reaches disk until you ask for a
save, and replacing an existing file requires explicit confirmation, so a
mistaken filename cannot destroy a network.

Moving a node or changing its radio clears the calculated links, because those
were solved against a network that no longer exists. Ask the assistant to run
`solve_links`, wait for completion, and explicitly save if the refreshed links
should be kept. The desktop's **Analysis → Recalculate → All Links** is an alternative.

Comparing candidate locations does not require editing anything. Asking "which of
these places would serve the most people" computes coverage from the coordinates
directly, so nothing is added to your network and there is nothing to undo.

## When RidgeCast cannot answer

The assistant records gaps through `report_limitation`: what was asked, what was
tried, and what was missing. The file is the configured `--limitation-log` path.
The default `docs/review/mcp-limitations.md` is relative to the server's working
directory; it lands in the repository when the server starts there. For a
packaged server, choose an absolute writable path as in the registration example.
If writing fails, the assistant should report that failure rather than say the
gap was recorded. See the [log-path reference](../reference/mcp-server.md#invocation).

Read it periodically. It is a list of feature requests written from real tasks
rather than guessed at. Treat the entries as field reports to triage, not as
agreed work.

## Related pages

- [MCP server reference](../reference/mcp-server.md) — every tool and argument
- [Evaluate a radio link](evaluate-a-radio-link.md) — the same analysis in the application
- [Find and validate a candidate site](find-and-validate-a-site.md) — the interactive Site Finder
- [Model limitations](../reference/model-limitations.md) — what the predictions do and do not mean
- [Work offline and manage cached data](work-offline-and-manage-caches.md) — the caches the server shares
