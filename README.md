# Integrated Virtual Equipment Simulator

A standalone, offline-first engineering workshop built with Godot. The repository began as an empty scaffold; no HLOS inventory report or equipment appendix was present in the checkout. The catalogue therefore deliberately contains no invented HLOS records. See [the feasibility report](docs/TECHNICAL_FEASIBILITY.md), [inventory status](docs/EQUIPMENT_CATALOG.md), and [implementation status](docs/IMPLEMENTATION_STATUS.md).

## Run

Install Godot **4.7.2 stable** (standard editor build; official Windows 10 x86_64 package for Windows), import this folder as a project, then press **F6** or **F5**. Godot is not bundled. The project uses the Compatibility renderer and has no third-party runtime dependencies.

On Linux, run `godot --path .` (or `godot4 --path .`). A headless smoke test is `godot --headless --path . --editor --quit` followed by `godot --headless --path . --quit-after 3`.

## Current functional scope

Phase 1 prototype: generated 3D workshop, generic equipment registry and searchable palette, select/place/duplicate/remove equipment, inspect and move/rotate selected objects, camera orbit/pan/zoom, start/pause simulation clock, and save/load versioned JSON project files under the application user-data directory. Equipment definitions are explicitly generic and do not claim manufacturer accuracy. Engineering solvers, typed connections, instruments, fault models, Windows packaging, and SQLite persistence are not yet implemented.

## Tests

Run `python3 -m unittest discover -s tests -v` for repository/data contract tests. Install Godot 4.7.2 to run the engine smoke test described above. See `docs/VALIDATION.md` for what has and has not been exercised.

## Documents

- `docs/TECHNICAL_FEASIBILITY.md` — environment inspection and feasibility findings.
- `docs/EQUIPMENT_CATALOG.md` — report availability and catalog import policy.
- `docs/ARCHITECTURE.md` — subsystem boundaries and integration plan.
- `docs/SIMULATION_MODELS.md` — initial model classifications and planned contracts.
- `docs/ASSET_REGISTER.md` — generated assets and licensing rules.
- `docs/PERFORMANCE.md` — 8 GB target plan and unmeasured status.
- `docs/VALIDATION.md` — test evidence and limitations.
- `docs/IMPLEMENTATION_STATUS.md` — completed, partial, and not-yet-built work.
- `docs/RELEASE_NOTES.md` — development milestones.
