# Asset and license register

| Asset | Source/method | License/rights | Technical accuracy | Status |
|---|---|---|---|---|
| Workshop floor, lighting and camera | Generated at runtime in GDScript from Godot built-in primitives | Original project code; project license applies | Environment blockout only | Implemented |
| Generic bench / PC / switch / multimeter blockouts | Generated at runtime from box meshes and material colors | Original project code; project license applies | Scale and component details are intentionally unspecified; not a manufacturer model | Implemented, Level 1 visual only |
| External/manufacturer/third-party assets | None used | Not applicable | Not applicable | No external assets imported |

The repository currently has no `LICENSE` file; project redistribution terms still need to be selected and documented before a release. Godot is a separate MIT-licensed engine; this application does not bundle it. External CAD/model import requires provenance, verified license/redistribution rights, scale, connector positioning and performance review before inclusion. Unknown licensing means do not redistribute.

Future work should use original low-poly assets or explicitly licensed assets, with LODs and internal geometry loaded only when inspection requires it. No purchased assets have been acquired.
