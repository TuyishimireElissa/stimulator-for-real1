# Architecture

## Phase 1 component map

```text
Godot main scene (scripts/core/workshop.gd)
  ├── equipment catalog loader ── data/equipment/catalog.json
  ├── procedural world and camera
  ├── generated equipment instances and selection metadata
  ├── runtime-built UI: searchable palette, inspector, controls, status
  └── versioned portable JSON save/load

Planned isolated domain services (not implemented yet)
  ├── equipment definition/schema validation
  ├── typed connection graph and compatibility validation
  ├── deterministic event scheduler
  ├── electrical (MNA), digital/event, network (discrete event), CPU, thermal/power models
  ├── instrument adapters reading domain state
  ├── fault injection and evidence/diagnostics
  └── SQLite persistence + migration layer / JSON interchange
```

The Phase 1 prototype is deliberately small: current code is a single workshop controller, not an assertion that the final architecture is complete. As domains are implemented, move them into independent scripts with typed data contracts and unit tests. Do not put circuit/network/CPU behavior into scene presentation code.

## Target layer boundaries

1. **Desktop shell:** window settings, startup, application settings, input, logging and packaging.
2. **World/presentation:** rendering, camera, placement, pick/inspect, overlays; consumes model state but does not own engineering equations.
3. **Definition registry:** versioned equipment identity/specification, ports, components, capability and provenance.
4. **Connection graph:** typed endpoint/connector/protocol, direction and parameter validation; only validated links enter domain solvers.
5. **Simulation domains:** independent models and schedulers; communicate via typed state/events, fixed-step or discrete-event scheduling as appropriate.
6. **Instrumentation:** measurement requests and readings derived from domain state, with unit/source/range/time metadata.
7. **Faults/diagnostics:** activate/deactivate model faults, propagate effects, expose evidence and recovery.
8. **Persistence:** migrate/versioned SQLite records and portable project JSON with atomic validation and recovery.

## Dependency map

```text
definitions -> instances -> ports/interfaces -> connection graph
                                            -> domain models -> state/events
                                                          -> instruments/graphs
fault definitions -> affected model state -> symptoms/evidence -> repair
all project state -> persistence -> restore -> validation -> running world
```

3D asset and UI layers depend on stable identifiers and public state views, not on solver internals. A domain may expose a `step(dt)` fixed-step contract or event queue, but simulation time policy belongs to the scheduler. No solver is implemented in Phase 1.

## Data and errors

`data/schemas/equipment.schema.json` is the initial equipment-definition contract. Definition IDs are stable snake-case strings; each definition has a version and source. `null`/empty technical fields mean unknown/not specified, never zero. Invalid/missing definitions should be rejected with diagnostics rather than causing a scene crash. Connections and simulation models will each get separately versioned schemas/contracts before use.

Phase 1 project JSON is tagged `format: virtual-equipment-project` and `schema_version: 1`. It persists placement, orientation and elapsed prototype clock only. It is not SQLite and does not yet persist connections, equipment configuration, faults, component states, measurement history, or simulation solver state.

## Decisions

- Godot 4.7.2 stable; GDScript; Compatibility renderer for hardware reach.
- Procedural primitives initially, to avoid unverified external assets and licenses.
- JSON equipment definitions and JSON project exchange initially; SQLite integration is a tracked later decision.
- Offline-first: no service/account dependency.
- Determinism and numerical validity must be evaluated separately per future model; the current wall-clock timer is not a deterministic simulation.
