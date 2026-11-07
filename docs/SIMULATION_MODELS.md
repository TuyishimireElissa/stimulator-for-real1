# Simulation model register

## Current models

| Model | Fidelity | Parameters/source | Validation | Status/limitations |
|---|---|---|---|---|
| Equipment blockout geometry | Level 1 visual | Original primitive boxes; no real dimensions/specifications | Manual code/data contract tests | Implemented. No ports, operation or engineering behavior. |
| Prototype elapsed-time display | Not an engineering model | Frame delta from Godot runtime | Manual source inspection only | Implemented as UI clock only; not deterministic; no equipment responds to it. |

## Planned contracts and honest initial boundaries

| Domain | Initial feasible model | Required parameters/evidence | Current status |
|---|---|---|---|
| PC assembly | Data-driven compatibility constraints and a finite-state POST/boot model | Exact board/CPU/RAM/PSU data; compatibility references and state tests | Not implemented; no source catalogue |
| Electrical | DC modified nodal analysis for supported linear elements, later controlled non-linear devices and transient integration | Values, units, tolerances, solver method/limits, analytical reference circuits | Not implemented |
| Digital logic | Discrete-event logic with explicit propagation delay for supported parts | Truth tables/timing references | Not implemented |
| Networking | Sandboxed discrete-event frames/packets and explicit L2/L3 services | Protocol behavior, topology and deterministic packet tests | Not implemented |
| CPU | Documented educational ISA/emulator interface before broader models | ISA source, instruction test vectors, timing stated as functional/estimated | Not implemented; no claim of commercial microarchitecture fidelity |
| Embedded | Explicit board/pin/peripheral model; emulator only when legal and validated | Board datasheet, voltage/current/time constraints | Not implemented |
| Thermal/power | Lumped thermal resistance/capacitance network and budget accounting | Thermal/power/ambient parameters and analytical validation | Not implemented |
| Instruments | Measurement adapters with source, unit, timestamp, input loading/range/limits | Instrument specs plus comparisons to solver state | Not implemented; prototype multimeter takes no measurements |

## Required future per-model metadata

Record model name/version; parameter source and provenance; assumptions; inputs/outputs with units; supported range; numerical method and step/event policy; limitations; validation cases/reference results/tolerances; and whether values are generic or manufacturer-specific. Validation must not conceal model error behind arbitrary tolerances. Lack of a value must be reported as unavailable, never synthesized as a reading.

## Fidelity levels

Use Level 1 visual, Level 2 functional, Level 3 engineering, and Level 4 high-fidelity validated only as specified in the product brief. A catalogue capability should only be surfaced when code and tests demonstrate it. Current prototype entries are Level 1 only.
