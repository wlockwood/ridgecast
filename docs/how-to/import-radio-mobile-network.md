# Import a Radio Mobile network

Use this guide to turn a Radio Mobile CSV export into a RidgeCast network.
If you want an independent project, choose **File → New** first; otherwise, this
import merges the imported nodes and system profiles into the open network,
retaining any existing unrelated nodes while updating matching system profiles
and reporting any node-name collisions (this merge can be undone via **Edit → Undo**).

1. Keep the matching `_Unit.csv`, `_System.csv`, and `_NetData.csv` files in the
   same directory. Their text before the suffix must match: for example,
   `maplenet_Unit.csv`, `maplenet_System.csv`, and `maplenet_NetData.csv` form
   one valid set.
2. Choose **File → Import → Radio Mobile Units (CSV)…**.
3. Select the `_Unit.csv` file. RidgeCast locates the other two files beside it.
4. Review any collision or validation messages before continuing. A successful
   import leaves the expected named nodes on the map; correct the reported file
   or value and repeat the import if RidgeCast rejects it or the result is not
   the network you expected.
5. Choose **View → Fit to Active Nodes** and inspect the imported sites.
6. Save the result with **File → Save As…** before making extensive edits.

Select two nodes to confirm that their system assignments and link parameters
produce a plausible result. Compare frequency, antenna height, transmit power,
and the resulting fade margin with the original design; imported data is
planning input, so validate RF assumptions independently.

If RidgeCast reports missing files, compare the complete filename prefix and
extension of all three files. The source checkout's `example-rm-imports/`
directory contains a known-good `maplenet_*` sample you can import unchanged to
check the workflow.

For the exact columns read, how a unit's system and nets are chosen, and what
happens when a node already exists, see
[Import formats and limits](../reference/import-formats.md#radio-mobile-csv).
