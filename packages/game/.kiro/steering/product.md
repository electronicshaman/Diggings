# Product Overview

## Core Identity
**Card Battler Prototype** is a roguelite card battler set in Australian gold rush meets Lovecraftian horror. The game features 1v1 card duels and hex-based exploration.

## Key Differentiators
- **Open hex exploration** instead of linear paths - player-driven navigation across the outback
- **1v1 duels only** - intimate strategic battles with visible enemy intents
- **Seeded runs** with deterministic gameplay for debugging and reproducibility
- **Digital-first card effects** - modifications like Evolving, Viral, Phasing impossible in physical games

## Core Game Loop
Explore map → Find encounters → 1v1 card duels → Manage resources → Progress or die

## Resource System
- **Health & Sanity** - dual failure conditions (physical death or madness)
- **Gold** - primary currency and some card costs
- **Corruption** - persistent negative resource that accumulates
- **Energy** - standard card-playing resource (resets each turn)

## Card Categories
- **Attack** - Direct damage cards
- **Skill** - Utility effects (defense, buffs, debuffs, card draw)
- **Power** - Persistent combat upgrades (one per combat)
- **Fortune** - Risk/reward cards with randomized effects
- **Status/Curse** - Deck pollution cards (temporary/persistent)

## Character Classes
- **Prospector** (Fortune cards) - Risk/reward gambling mechanics
- **Bushranger** (Attack cards) - Aggressive damage dealing
- **Tracker** (Skill cards) - Defense and survival focus
- **Publican** (Power cards) - Healing and sanity management
- **Preacher** (Fortune cards) - 
## Development Philosophy
- **Start simple, iterate** - 100-line prototypes before complexity
- **Data-driven design** - everything configurable via Resources
- **Fail fast** - rapid prototyping and immediate feedback
- **Digital-first** - leverage video game capabilities over physical limitations