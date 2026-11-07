# Equipment catalogue and source reconciliation

## Source status

No HLOS equipment inventory report or structured appendix was included in the repository or available files inspected for this task. Therefore **zero HLOS master equipment records and zero software/resource records were extracted**. The specification's counts (49 master records, 25 software/tool resources, 303 curriculum topic records) are noted as expected source content only; they are not a substitute for the records themselves.

The 303 curriculum topic records are intentionally excluded. No course, curriculum, lesson, student, or progress-management content is part of this application.

## Prototype registry

`data/equipment/catalog.json` contains four original, generic UI blockout definitions (workbench, desktop computer, network switch, multimeter). They are **not** claimed to be any of the 49 report records. They have no manufacturer/model identity, numeric specifications, ports, supported measurements, or simulation model. The `visual-only` limitations are explicit in each definition. These exist solely to exercise Phase 1 registry and object placement.

## Unresolved source fields

Until the report and appendix are available, every inventory-specific field remains unresolved, including record IDs, exact names/category, manufacturer/model, purpose/use, limitations, safety notes, interfaces, model-specific technical parameters, license/asset references, and the mapping between the 49 physical records and the separate 25 software resources. No missing data is inferred from the headline counts.

## Import policy for a later source handoff

1. Preserve original source row identifiers and wording in a provenance field.
2. Keep physical equipment and software/tool resources in separate collections.
3. Record normalization changes and unresolved values; do not fill missing numeric fields from visual guesses.
4. Validate imported definitions against `data/schemas/equipment.schema.json` and a future resource schema.
5. Never import the curriculum topic list as simulator modules.
