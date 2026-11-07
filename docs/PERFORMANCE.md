# Performance plan — 8 GB RAM baseline

## Current workload

Procedural workshop shell and four generic JSON records; no large textures, imported meshes, native extensions, solvers or third-party runtime. Godot Compatibility renderer, 1440×900 default. This is a design choice, not a measured performance result.

## Targets and implementation policy

- Keep the core executable standalone/offline and avoid requiring an account or network.
- Begin with generated low-poly geometry and no large texture dependencies.
- Add adjustable low/medium/high render presets before large asset sets.
- Use mesh/material reuse and instancing for repeated parts; keep collision shapes simple.
- Load assets and domain models on demand. Add LOD and culling as scene scale warrants.
- Throttle inactive model updates; use a central fixed-step / discrete-event scheduler instead of per-object frame loops.
- Profile memory, CPU, GPU and solver throughput on a real Windows 10 8 GB machine before claiming a target is met. Keep expensive model domains opt-in and isolated.
- Bound log/event and measurement histories; safely handle oversized projects and parse failures.

## Measurements

No Windows target machine is available in the current environment. RAM usage, CPU use, startup time, frame rate, and long-session stability are **not measured**. Linux sandbox and headless import checks, if available, do not substitute for Windows or integrated-GPU testing. Record machine, OS build, GPU/driver, scene/object count, settings, workload and capture method for future benchmarks.
