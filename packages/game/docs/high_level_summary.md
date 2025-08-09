# High-Level Summary: Gold Rush Lovecraft Game Design

## Core Game Identity

**Genre**: Roguelite card battler   
**Setting**: Australian gold rush meets Lovecraftian horror  
**Core Loop**: Explore map → Find encounters → 1v1 card duels → Manage resources → Die or complete objectives

## Key Differentiators from Slay the Spire

### 1. Open Hex Exploration vs Linear Paths

- **Player-driven exploration** - choose your own path across the outback
- **Multiple objectives per run** (claim gold veins, seal breaches, hunt bounties) rather than just "reach the top"

### 2. Day/Night Cycle System

- **Action-based time progression** (not real-time)
- **Fog of war changes with time** - visibility shrinks at night
- **Night combat costs sanity** - risk/reward for pushing forward
- **Time as a resource** - deciding when to camp vs when to push

### 3. 1v1 Duels Only

- **Single enemy encounters** for more intimate, strategic battles
- **No target selection needed** - damage hits enemy, block/heal affects self
- **Enemy uses cards too** - visible patterns you can learn and counter
- **Simpler state management** - always just player vs enemy

### 4. Card Modification System

- **Digital-only effects** that physical cards can't do:
  - **Evolving**: Cards permanently gain +1 damage each play
  - **Viral**: Cards duplicate themselves in your deck
  - **Phasing**: 50% chance to not exist each combat
  - **Unstable**: Randomly becomes different card each combat
- **Multiple mods per card** - create unique combinations
- **Location-based modifications** - different sites give different mods

### 5. Core Card Types - Mechanical Categories

- **Attack**: A card that deals direct damage to an enemy and may have a secondary effect. Attack cards are the primary way to reduce enemy health and end combat encounters.

- **Skill**: A card with diverse utility effects including defense, buffs, debuffs, card draw, energy manipulation, and other non-damage actions. Skills can be offensive or defensive but cannot deal direct damage (only indirect damage through debuffs).

- **Power**: A persistent upgrade that lasts for the entire combat encounter. Powers provide ongoing effects like stat bonuses, triggered abilities, or playstyle modifications. Each copy of a Power can only be played once per combat.

-**Fortune**: A card with randomized or luck-based effects that embody risk/reward gameplay. Fortune cards may have variable outcomes, gambling mechanics, or chance-based triggers.

- **Status**: A temporary card added to the deck during combat. Status cards are designed to bloat the deck and prevent drawing beneficial cards, often with additional negative effects. They are automatically removed from the deck at the end of combat.

- **Curse**: An unplayable card added to the deck through events or penalties. Like Status cards, Curses bloat the deck and may have negative effects, but they persist in the deck until actively removed through other means.

*Note: These are theme-agnostic mechanical categories. Themes layer flavor and visual design on top of these core functions.*

## Resource System

- **Health & Sanity** - two ways to lose (physical death or madness)
- **Gold** - Currency and some card costs
- **Corruption** - Persistent negative resource that accumulates
- **Energy** - Standard card-playing resource (resets each turn)

## Character Classes (Start with 4)

Each specializes in one card type:

- **Prospector** (Gamble cards) - Risk/reward gameplay
- **Bushranger** (Guns cards) - Aggressive damage
- **Tracker** (Grit cards) - Defense and survival  
- **Publican** (Grog cards) - Healing and sanity management

## Eldritch Curios

Persistent run modifiers (like relics) with Australian gold rush + cosmic horror themes:

- **Common**: Minor benefits with quirks ("Prospector's Spectacles" - see further but one tile is always hidden)
- **Rare**: Powerful but corrupting ("The Antipodean Star" - walk on void tiles at night but reality inverts)

## Technical Architecture Insights

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

1. **The tension of exploration** - Do you have enough daylight to reach town? Is that gold worth the sanity cost?

2. **Meaningful deck pollution** - Cards can become corrupted, viral, or unstable - your deck evolves during the run

3. **Australian Gothic horror** - Unique theme combining historical gold rush with cosmic dread

4. **Time as pressure** - Not just "how many fights can you win" but "can you achieve your goals before nightfall/madness"

5. **Digital-first design** - Effects impossible in physical games make each run feel different

## MVP Priority Order

1. **Combat engine** - Get 1v1 duels working perfectly
2. **Basic cards & effects** - Just damage, block, heal to start
3. **Character classes** - Different starting decks and one unique mechanic each
4. **Card modifications** - Start with simple ones (cost reduction, damage boost)
5. **Hex exploration** - Basic movement and tile types
6. **Day/night cycle** - Time system and visibility changes
7. **Polish & content** - Only after everything else works

## Key Design Principles

- **Fail fast** - If something isn't fun in the prototype, change it immediately
- **Data-driven** - Everything should be tweakable without code changes
- **Show, don't hide** - Enemy intents visible, time effects clear
- **Respect the player's time** - 30-45 minute runs, quick combat resolution
- **Embrace the digital medium** - Do things only possible in video games
- **Fail fast** - If something isn't fun in the prototype, change it immediately
- **Data-driven** - Everything should be tweakable without code changes
- **Show, don't hide** - Enemy intents visible, time effects clear
- **Respect the player's time** - 30-45 minute runs, quick combat resolution
- **Embrace the digital medium** - Do things only possible in video games
