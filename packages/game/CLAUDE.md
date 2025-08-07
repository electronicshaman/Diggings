# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 card battler prototype combining Australian Gold Rush themes with Lovecraftian horror. The game features roguelite mechanics with hex-based exploration and 1v1 card duels. The project is implementing a clean, theme-agnostic architecture to support multiple themes.

## Development Commands

### Running the Game
```bash
# Open in Godot editor (macOS path from VSCode settings)
/Applications/Godot.app/Contents/MacOS/Godot --editor

# Run the game directly
/Applications/Godot.app/Contents/MacOS/Godot

# Or simply use godot if in PATH
godot --editor
godot
```

### Godot Project Structure
- Engine: Godot 4.4
- Rendering: Mobile renderer
- Cache directory: `.godot/` (gitignored)

## Architecture Overview

### Theme-Agnostic Core Design

The project is implementing a **clean slate theme system** where themes are data packages that can be loaded dynamically. "The Rush" (Australian Gold Rush) is the primary theme.

**Key architectural principles:**
- Effects as data, not behavior
- Centralized effect resolver
- State machine approach: PLAYER_TURN → RESOLVE_EFFECTS → ENEMY_TURN
- Everything as Godot Resources for hot-reloading

### Directory Structure (Planned)

```
themes/                          # Theme system (TO BE CREATED)
├── theme_manager.gd            # Core theme loader
├── theme_config.gd             # Theme configuration resource
├── card_type_definition.gd     # Card type definitions
└── the_rush/                   # Australian theme
    ├── theme_config.tres       # Theme configuration
    ├── characters/             # Character classes
    ├── cards/                  # Cards by type
    │   ├── gold/              # Attack cards
    │   ├── grit/              # Skill cards
    │   ├── grog/              # Power cards
    │   └── gamble/            # Fortune cards
    ├── enemies/               # Enemy definitions
    └── curios/                # Item definitions

archive/                        # Legacy content (TO BE CREATED)
└── wild_west/                 # Previous theme for reference

scripts/                        # Core game logic (TO BE CREATED)
├── cards/                     # Card system
├── combat/                    # Combat engine
├── exploration/               # Hex map system
├── managers/                  # Game managers
└── ui/                        # UI controllers

resources/                      # Game data (TO BE CREATED)
├── character_classes/         # Base character data
├── card_data/                 # Base card data
└── enemy_data/                # Base enemy data
```

### Core Systems

1. **Combat Engine** - 1v1 card dueling
   - Single enemy encounters only
   - Visible enemy intents
   - Card-based turns

2. **Card System**
   - Four mechanical categories: Attack, Skill, Power, Fortune
   - Themed as Gold/Grit/Grog/Gamble for Australian theme
   - Digital-only modifiers: Evolving, Viral, Phasing, Unstable

3. **Resource Management**
   - Health & Sanity (dual loss conditions)
   - Gold (currency)
   - Corruption (persistent negative)
   - Energy (per-turn resource)

4. **Exploration**
   - Hexagonal world map
   - Day/night cycle (action-based)
   - Multiple objectives per run

### Development Strategy

1. **Start with 100-line prototype** - Basic damage/block/turns
2. **Theme-agnostic initial development** - Type1/Type2/Type3/Type4
3. **Iterate based on fun** - Change immediately if not engaging
4. **Data-driven design** - Everything tweakable without code

### Current TODO Focus

The project is implementing a clean architecture transition as detailed in `docs/THEME_AGNOSTIC_CORE_TODO.md`. Key phases:

1. **Phase 1**: Core theme framework architecture
2. **Phase 2**: Theme manager implementation
3. **Phase 3**: Template system for future themes

### Character Classes (Australian Theme)

- **Bushranger** - Outlaw survival, bush warfare
- **Tracker** - Aboriginal guide, survival expert
- **Miner** - Underground specialist, explosives
- **Prospector** - Gold seeker, claim finder
- **Doctor** - Frontier medic
- **Publican** - Pub owner, social networks
- **Priest** - Missionary, moral authority
- **Swagman** - Wandering worker, jack-of-trades

## Development Guidelines

### Debugging and Logging

**ALWAYS use GLog for debugging output.** The project has a custom logging system that:
- Automatically checks `const DEBUG_ENABLED: bool` in each file
- No need for `if DEBUG_ENABLED:` before log calls
- Clean syntax: `GLog.debug("message")`, `GLog.warn("message")`, `GLog.error("message")`
- Automatic source file detection and colored output
- See `GLOG_USAGE_GUIDE.md` for full documentation

**Example usage in any .gd file:**
```gdscript
const DEBUG_ENABLED: bool = true  # Toggle per file

func my_function():
    GLog.debug("Function called")  # No if statement needed
    GLog.warn("Something suspicious")
    GLog.error("Something went wrong")
```

## Key Design Principles

- **Fail fast** - Change immediately if not fun
- **Show, don't hide** - Visible information for strategic decisions
- **30-45 minute runs** target
- **Digital-first** - Embrace video game possibilities
- **Theme as data** - Core mechanics separate from flavor