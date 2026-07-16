# High-Level Summary: Gold Rush Lovecraft Game Design

Last verified: 2026-07-13

## Active Milestone

The active milestone is the deterministic curated three-fight mini-run.

- **New Game flow:** static class selection, then three fights with a
  card-or-recovery choice after each of the first two fights, ending in a
  summary.
- **Quick Duel:** single-fight developer sandbox, independent of the curated
  run.
- **Frozen:** Atlas, content-kit, generated narrative, the narrative runtime,
  maps, shops, and saving.
- **Canonical design:**
  `docs/superpowers/specs/2026-07-12-core-game-recovery-design.md` (repo
  root).

## Core Game Identity

**Genre**: Roguelite card battler
**Setting**: Australian gold rush meets Lovecraftian horror
**Core Loop**: 1v1 card duels → Manage resources → Build deck → Advance through the curated three-fight run

## Key Differentiators from Slay the Spire

### 1. Seeded Runs and Debuggable Systems (Current)

- **SeedManager autoload** drives deterministic runs
- **Seed visible in UI** when enabled via `GameSettings.show_seed_in_ui`
- **Debug HUD** and **DebugController** support fast iteration (HUD toggled via "HUD" input action)

### 2. 1v1 Duels Only

- **Single enemy encounters** for more intimate, strategic battles
- **No target selection needed** - damage hits enemy, block/heal affects self
- **Enemy uses cards too** - visible patterns you can learn and counter
- **Simpler state management** - always just player vs enemy

### 3. Card Modification System (Planned)

- Digital-first effects such as Evolving, Viral, Phasing, Unstable
- Multiple mods per card and site-based modification opportunities
- Status: Design documented; implementation tracked in future milestones

### 4. Core Card Types - Mechanical Categories

- **Attack**: A card that deals direct damage to an enemy and may have a secondary effect. Attack cards are the primary way to reduce enemy health and end combat encounters.

- **Skill**: A card with diverse utility effects including defense, buffs, debuffs, card draw, energy manipulation, and other non-damage actions. Skills can be offensive or defensive but cannot deal direct damage (only indirect damage through debuffs).

- **Power**: A persistent upgrade that lasts for the entire combat encounter. Powers provide ongoing effects like stat bonuses, triggered abilities, or playstyle modifications. Each copy of a Power can only be played once per combat.

-**Fortune**: A card with randomized or luck-based effects that embody risk/reward gameplay. Fortune cards may have variable outcomes, gambling mechanics, or chance-based triggers.

- **Status**: A temporary card added to the deck during combat. Status cards are designed to bloat the deck and prevent drawing beneficial cards, often with additional negative effects. They are automatically removed from the deck at the end of combat.

- **Curse**: An unplayable card added to the deck through events or penalties. Like Status cards, Curses bloat the deck and may have negative effects, but they persist in the deck until actively removed through other means.

*Note: These are theme-agnostic mechanical categories. Themes layer flavor and visual design on top of these core functions.*

## Resource System (Current)

- **Health & Sanity** - two ways to lose (physical death or madness)
- **Gold** - Currency and some card costs
- **Corruption** - Persistent negative resource that accumulates
- **Energy** - Standard card-playing resource (resets each turn)

## Character Classes

  | Class      | Resource | Max | Theme                   |
  |------------|----------|-----|-------------------------|
  | Bushranger | Ammo     | 6   | Tactical gunfighter     |
  | Prospector | Fever    | 10  | Gold madness/corruption |
  | Tracker    | Scent    | 5   | Primal hunting          |
  | Publican   | Brew     | 8   | Hospitality/social hub  |
  | Preacher   | Faith    | 10  | Religious fervor        |

  
## Eldritch Curios

Persistent run modifiers (like relics) with Australian gold rush + cosmic horror themes:

- **Common**: Minor benefits with quirks ("Prospector's Spectacles" - see further but one tile is always hidden)
- **Rare**: Powerful but corrupting ("The Antipodean Star" - walk on void tiles at night but reality inverts)

## Technical Architecture Insights (Current)

### Start Simple, Then Iterate

- **Begin with 100-line prototype** - just damage, block, basic turns
- **No polish initially** - colored rectangles and text
- **Test core loop first** - is it fun to play cards and see results?
- **Add complexity gradually** - modifiers, classes, exploration later

### State Machine Approach

- **Effects as data, not behavior** - effects just describe what to do
- **Centralized resolver** - one place handles all effect execution
- **Clear state flow** - PLAYER_TURN → RESOLVE_EFFECTS → ENEMY_TURN → repeat

### Development Strategy

- **Keep it theme-agnostic initially** - card types are just Type1/Type2/Type3/Type4
- **Make everything Resources** in Godot - hot-reloadable data files
- **Parallel development** - keep old system while building new
- **Test constantly** - every feature should be playable immediately

## What Makes This Unique

1. **Meaningful deck pollution** - Cards can become corrupted, viral, or unstable - your deck evolves during the run

2. **Australian Gothic horror** - Unique theme combining historical gold rush with cosmic dread

3. **Digital-first design** - Effects impossible in physical games make each run feel different

4. **Dual health system** - Health and Sanity provide two distinct failure states and strategic considerations

## MVP Priority Order (Roadmap)

1. **Combat engine** - Get 1v1 duels working perfectly (done)
2. **Basic cards & effects** - Damage, block, heal, status effects (done)
3. **Character classes** - Different starting decks and unique mechanics (done)
4. **Handler system** - Modular effect processing via HandlerRegistry (done)
5. **Curio system** - Persistent run modifiers (done)
6. **Card modifications** - Cost reduction, damage boost, etc. (in progress)
7. **Polish & content** - Ongoing

## Key Design Principles

- **Fail fast** - If something isn't fun in the prototype, change it immediately
- **Data-driven** - Everything should be tweakable without code changes
- **Show, don't hide** - Enemy intents visible, time effects clear
- **Respect the player's time** - 30-45 minute runs, quick combat resolution
- **Embrace the digital medium** - Do things only possible in video games

## Planned Systems

- Card modification and upgrade mechanics
- Additional character class balancing
- Expanded enemy variety and patterns

## Current Feature Snapshot

- 1v1 duels with player/enemy turns and visible intents
- Core card categories: Attack, Skill, Power, Fortune; Status and Curse as deck pollutants
- Seeded runs via SeedManager; seed display toggle in UI settings
- Curated three-fight run (`RunSession`) launched from static class selection: persistent player state, deck growth, two card-or-recovery choices, victory/defeat summary
- Quick Duel remains a single-fight developer sandbox, separate from the curated run
- Autoload managers: GameSettings, EventBus, SaveSystem, ResourceManager, SeedManager, GLog, GameManager, DeckManager, SceneManager, CurioManager, RunHistoryManager, DebugHUD, HandlerRegistry
