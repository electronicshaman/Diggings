# Enemy Patterns

Last verified: 2025-08-18

## Implemented Enemies (snapshot)

Detected enemy resources in `data/enemies/`:

- `claim_jumper.tres`
- `mad_dog_morgan.tres`

If more exist, expand this list after adding assets.

## Pattern Structure

Each enemy should define:

- Name and description
- Stats: health, damage profile, initiative
- Intent pattern: telegraphed actions per turn
- Special mechanics: corruption, on-hit effects, phases
- Loot table

## Next Steps

- Document intents for existing enemies by inspecting their `.tres` and scripts under `scripts/enemies/` (if present).
- Add a table per enemy with at least two example turns of intents.
- Link to encounter definitions in `data/encounters/` where relevant.
