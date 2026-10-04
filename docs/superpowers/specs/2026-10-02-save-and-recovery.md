# Save and recovery

Implement the user-approved review: explicit Save writes the chosen project file
and establishes a clean baseline; first Save asks for a location. Autosave writes
independent per-document recovery snapshots without overwriting project files or
marking them saved. Show unsaved, saving, saved, and failed status and shortcuts.

New, Open, Recent, replacement imports, update installation, and close share
Save / Don't Save / Cancel protection. Failed/canceled saves retain the current
document. Workers finish before closing; I/O and file dialogs stay off the UI
thread. Stage replacement imports; reject stale background merge revisions.

Offer recovery at startup with original paths and capture times. Retain records
until explicit save or deliberate discard; preserve corrupt records with warnings.
Read legacy defaults using newest valid format. Shared writes are atomic.

Preserve unrelated dirty work and compatible serialized project configuration.
Do not stage or commit. Document behavior; all new controls have tooltips.
