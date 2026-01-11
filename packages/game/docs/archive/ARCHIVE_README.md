# Archived Documentation

This folder contains documentation that is no longer current but may be useful for historical reference.

## Why These Documents Were Archived

Documents in this folder describe features, systems, or plans that have been:
- **Removed** - The system was removed from the codebase
- **Superseded** - Replaced by a different implementation
- **Abandoned** - Planning documents for features that were not implemented
- **Outdated** - No longer reflects current architecture

## Archived Files

### Removed Systems

| File | Description | Reason Archived |
|------|-------------|-----------------|
| `ENCOUNTER_FLOW.md` | Encounter system architecture | Encounter system removed |
| `NODE_TYPES.md` | Map node type definitions | Hexmap system removed |
| `remove-hexmap.md` | Plan for hexmap removal | Removal completed |
| `ENCOUNTER_PLAN.md` | Encounter system design | System not implemented |
| `GAMEEFFECT_REFACTOR.md` | Effect system refactor plan | Replaced by HandlerRegistry |
| `REFACTOR_PLAN.md` | SOLID refactor roadmap | Core refactoring completed |
| `DOCS_REFRESH_PLAN.md` | Documentation refresh plan | Refresh completed |

### Legacy Design Documents

| File | Description |
|------|-------------|
| `PROJECT_OVERVIEW.md` | Old project overview (superseded by `high_level_summary.md`) |
| `GENERIC_EFFECT_SYSTEM.md` | Old effect system design |
| `STRUCTURE_UPGRADE_README.md` | Old structure planning |
| `CARD_MIGRATION.md` | Card system migration guide |
| `Curios.md` | Old curio design (superseded by `CURIOS_CATALOG.md`) |
| `theme_agnostic_core.md` | Theme system design |
| `CURRENT_CARDS_REFERENCE.md` | Old card reference |
| `TESTING_GUIDE.md` | Old testing approach |

## Using Archived Documents

These documents should **not** be used for current development. They are kept for:
- Understanding historical design decisions
- Reference when investigating legacy code
- Context for why current systems work the way they do

For current documentation, see the main `docs/` folder.
