# Phase 0 — Technical feasibility report

**Assessment date:** 2026-11-07 (UTC)  
**Repository inspected:** `TuyishimireElissa/stimulator-for-real1`, initial commit `35bb51e`  
**Decision:** Proceed with Godot 4.7.2 stable for the desktop/3D shell, GDScript for orchestration, versioned JSON definitions and portable JSON project interchange in Phase 1. Keep engineering solvers isolated behind domain interfaces. Defer SQLite until a tested, maintained Godot integration is selected.

## Inspection findings

- The checkout contained only a 23-byte README and Git metadata. No HLOS report, appendix, CAD files, assets, tests, or existing application were present.
- There are no supplied PDFs, office files, or equipment reports in the inspected repository/home workspace search.
- Godot, Blender, and Windows are not installed in the current Linux sandbox. Python 3.11.2 is available.
- The current development branch is the Arena session branch. No existing project was overwritten.
- The user-described “49 master records” and “25 software/tool resources” are counts from the specification, not records available for import. The 303 curriculum topics are explicitly excluded.

## Engine and platform decision

GitHub's official Godot release API was queried on 2026-11-07. It reported `4.7.2-stable` as the latest stable 4.x release: [release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable), [official release API](https://api.github.com/repos/godotengine/godot/releases?per_page=8). The engine release has downloadable Linux and Windows builds. Godot 4's Compatibility renderer is selected to favor broad GPU compatibility and reduced graphics requirements. The project targets Windows 10 x86_64, but Windows 10 startup/rendering and packaging have **not** been tested in this Linux-only environment. This is a reasoned development baseline, not a certification of every Windows 10 GPU/driver combination.

The standard Godot editor/runtime has no built-in relational database API. Phase 1 implements versioned JSON project files using built-in Godot APIs, which are portable and offline. SQLite remains a planned persistence milestone: select and test a supported extension/binding before relying on it; do not silently claim JSON is SQLite.

## Scope and feasibility

The complete specification is a multi-year-scale simulation product, not a single code generation task. A credible delivery must expand in vertical slices and establish validation references per model. In particular, a full x86 commercial CPU, detailed electromagnetic electronics, CFD, vendor firmware, and unrestricted real-device emulation are not supportable as a single generic feature. The strongest safe approach is a documented model per supported device/class, with explicit assumptions, operating envelope, and test vectors. The initial desktop interaction shell is feasible now; engineering systems are not represented as implemented in this milestone.

### Risks and controls

| Risk | Control |
|---|---|
| Missing equipment inventory and source specifications | Import only when source report is supplied; keep current placeholders clearly generic and uncounted as HLOS records. |
| “High fidelity” conflated with visual accuracy | Give every model an evidence/validation record and fidelity level; show unsupported capability explicitly. |
| Native solver/DB dependencies destabilize low-end machines | Prefer isolated GDScript models first; benchmark before native code; keep JSON interchange and local offline use. |
| 8 GB memory and integrated GPU limits | Compatibility renderer, generated low-poly prototype geometry, lazy loading, no large external assets, later profile measured workloads. |
| Windows target cannot be exercised in Linux | Test Linux/headless parse now; require Windows 10 smoke and performance measurements before release. |
| Hazardous real-world interpretations | Clearly label simulation; do not model virtual readings as real measurements or safety proof. |

## Initial performance budget (targets, not measurements)

- Base project footprint: aim below 250 MiB RAM before catalogue/assets; keep high-detail assets unloaded unless inspected.
- Simulation workload is currently a paused/running clock only; no physics solver runs.
- Target integrated-GPU operation with Compatibility renderer, 1440x900 default, low-detail generated geometry, and adjustable display resolution.
- Future work should allocate performance budgets by domain and profile on an actual 8 GB Windows 10 target. No frame-rate, memory, startup-time, or CPU benchmark has yet been measured.

## Phase 0 outputs

See `EQUIPMENT_CATALOG.md`, `ARCHITECTURE.md`, `SIMULATION_MODELS.md`, `ASSET_REGISTER.md`, `PERFORMANCE.md`, `VALIDATION.md`, and `IMPLEMENTATION_STATUS.md`. Missing report fields are recorded as unresolved instead of being invented. Phase 1 has started as a small executable Godot project; its status and specific test evidence are kept in the implementation and validation reports.
