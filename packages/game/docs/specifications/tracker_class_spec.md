# Tracker Class Specification

Last verified: 2025-08-18

## Implementation Status: ✅ Resource Created

The Tracker character resource exists at `data/characters/tracker.tres` with identity, stats, abilities, and access rules.

## Character Overview

The Tracker represents the Aboriginal guide and frontier scout: preparation, survival, and information gathering.

## Mechanical Identity

- Primary Category: Skill
- Playstyle: Setup-and-execute, advantage via knowledge and positioning
- Signature themes: Pathfinding, Bush Medicine, Sacred Knowledge

### Starting Statistics

```text
Health: 50/50
Sanity: 105/105
Energy: 3/3
Gold: 15
```

## Implementation Snapshot (data/characters/tracker.tres)

- mechanical_specialization: Skill
- base_health: 50, base_sanity: 105, base_energy: 3, starting_gold: 15
- starting_deck: [] (placeholder), starting_deck_size: 15
- passive_abilities: ["Pathfinding", "Bush Medicine", "Sacred Knowledge"]
- active_abilities: ["Dreamtime Vision"]
- unique_resources: ["Setup Counter"]
- preferred_card_types: ["Grit"], forbidden_card_types: []

## Deltas vs Spec

- Starting deck is empty; needs a defined 15-card list. Recommend mirroring format used by Prospector (resource refs) or paths like Bushranger/Publican for consistency.
- Add concrete card list and interactions (e.g., reveal/prepare mechanics, bushcraft utilities).

## Next Steps

- Define starting deck composition and initial Tracker card set.
- Document class abilities behavior and any per-turn counters needed.
- Align with Event/Encounter systems for information/reveal interactions.
