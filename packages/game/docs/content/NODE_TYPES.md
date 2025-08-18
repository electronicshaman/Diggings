# Map Node Types

Last verified: 2025-08-18

This file catalogs the types of map nodes and their effects during a run.

## Source of Truth

- Data directory: `data/map_nodes/`
- Note: `MapNodeRegistry` is a legacy no-op stub; the current hexmap system should be used as reference when wiring behavior.

## Node Categories (from `data/map_nodes/`)

- Settlements: Towns where you can shop, heal, and trigger events
- Cities: Major hubs; expect richer shops and story entries
- Camps: Rest stops; options like rest, remove a card, small events
- Mines: Resource-heavy; more gold, higher corruption and danger
- POIs (Points of Interest): Unique interactions or curios
- Junctions: Routing nodes; may provide navigation benefits
- Bosses: Major encounters gating act or region progression

## Integration Notes

- Event nodes are typically triggered on selection via the Encounter system; see `docs/architecture/ENCOUNTER_FLOW.md`.
- Visual/UI cues live under `scenes/hexmap/`; node prefabs define appearance and interactions.
- When adding a new node type:
	1. Create a config/resource under `data/map_nodes/<category>/...`
	2. Ensure the hexmap scene recognizes the type and maps it to visuals/behavior
	3. Hook into EventBus or EncounterManager as needed for interactions

## Next Steps

- Extract concrete node definitions from `data/map_nodes/` contents and list per-node effects.
- Cross-link to any node-specific scenes or scripts once identified.

