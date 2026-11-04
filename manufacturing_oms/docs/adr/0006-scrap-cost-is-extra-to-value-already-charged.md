# Scrap Cost is the extra cost of scrapping; Material Value is charged per part started

2026-11-04, web app ticket 16, #41 ([web_app_plan.md](../web_app_plan.md) C27, C28).

Expected Profit already charges every part its Processing and Rework Costs as it goes, so a scrapped part has lost them before any Scrap Cost is added. The thesis cases nonetheless give cumulative Scrap Costs that include the upstream value again (spec A6). For a user's own Sequence, Scrap Cost is the cost of scrapping *on top of* what the part has been charged (disposal, nominally 0). A Sequence-level Material Value, paid for every part started, makes a scrapped part lose its material too. A Scrap Cost may be negative, for material recovered, but no lower than minus the Material Value: recovering more would make scrapping pay, and the optimiser would aim for it.

**Considered and rejected:**
- *Scrap Cost as the total value lost (material + processing to date), with the engine no longer charging Processing and Material separately for scrapped parts.* It changes Eq 3.78, which every oracle and preset is checked against.
- *A nominal Scrap Cost of Material + Processing Costs to date, with the engine unchanged.* It charges a scrapped part's value twice.

**Consequences:**
- The presets keep their cumulative Scrap Costs and a Material Value of 0, so their reference checks still hold. The engine treats both readings alike, as a cost added when a part is scrapped.
- The builder's "check" marker for cumulative Scrap Costs (C25) goes: nothing needs re-adding when earlier Processing Costs change.
