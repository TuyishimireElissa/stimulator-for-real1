# Validation and test evidence

## Environment

Python 3.11.2 is available in this workspace. Godot and Blender are absent; Windows 10 is unavailable. A temporary `gdtoolkit` 4.5.0 installation parsed/formatted the GDScript and `gdlint` passed. The official Godot release metadata was reachable, but downloading the 74.3 MiB editor/runtime failed at its GitHub release-asset redirect with a TLS connection error; therefore the engine itself was not run. The Godot project cannot be executed or GUI-tested in this environment until the engine is installed. Do not treat source inspection, a GDScript grammar parse, or Python tests as graphical application acceptance.

## Phase 1 tests

`python3 -m unittest discover -s tests -v` validates catalogue JSON parsing, unique definition IDs, required schema-equivalent metadata, generic-only provenance, no fabricated numeric specifications, and project configuration/main scene references. This checks static data/contracts, not Godot script parsing or UI behavior.

Once Godot 4.7.2 is installed, run:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 3
```

Then perform a GUI acceptance pass: launch; search and place each generic item; select/focus/move/rotate/duplicate/remove; start and pause the clock; save to a JSON file; restart/load and check positions/orientations. Repeat save/load with empty world, several objects, malformed file, duplicate/unknown IDs, window resize, and a long session. None of these GUI tests are yet evidenced.

## Test inventory

- Automated Python data/config tests: implemented; run locally before handoff.
- GDScript parse/headless startup: pending Godot executable.
- World navigation/selection, responsive layout, file dialogs: pending GUI execution.
- JSON round-trip and malformed-file behavior in Godot runtime: pending.
- Numerical engineering tests: none; no engineering model exists.
- Network/PC/electrical/instrument integration tests: none; not implemented.
- Windows compatibility/package/performance: not tested.

No claim of engineering correctness or functional instruments is made by this milestone.
