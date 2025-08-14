# Publican Class Specification

## Implementation Status:  Resource Created

The Publican character resource has been implemented at `data/characters/publican.tres` with full class mechanics, abilities, and card accessibility rules defined.

## Character Overview

The **Publican** represents the community cornerstone of frontier settlements - the pub owner who provides hospitality, sustenance, and social coordination. They embody patient, defensive gameplay with a focus on resource management, persistent effects, and late-game power spikes.

### Historical Context

- **Time Period**: 1850s-1890s Australian Colonial Era
- **Social Role**: Pub owners, innkeepers, community coordinators, social hubs
- **Economic Position**: Business owners profiting from providing hospitality and comfort
- **Cultural Identity**: Central figures maintaining community bonds and providing refuge

## Mechanical Identity

### Core Specialization

- **Primary Category**: **Power** (persistent effects and resource control)
- **Secondary Focus**: **Defense** (high block values and protective abilities)
- **Playstyle**: Patient, defensive, building toward powerful late-game effects
- **Resource Focus**: Energy generation and efficient resource management
- **Signature Mechanic**: **Fermentation** - cards that grow stronger when held longer

### Starting Statistics

```txt
Health: 50/50        # Standard (sturdy but not a frontline fighter)
Sanity: 95/95        # High (social stability, community leadership)
Energy: 4/4          # Above average (providing sustenance and energy)
Gold: 20             # High starting (successful business owner)
Corruption: 0        # Starts clean, focused on community service
```

## Class Mechanics

### 1. Social Hub (Core Passive)

**Effect**: Start each combat with +1 Energy.
**Implementation**:

- Triggers at combat start before first turn
- Provides consistent resource advantage
- Represents providing sustenance and energy to allies
**Strategy**: Enables more aggressive opening turns and higher-cost card plays

### 2. House Advantage (Economic Passive)

**Effect**: Gain +2 Gold from all victories.
**Strategy**: Better economic rewards for successful community leadership
**Flavor**: Profitable business operations in frontier settlements

### 3. Community Leader (Active Ability)

**Effect**: Once per combat, when you play a Defense card, gain 1 Energy.
**Strategy**: Rewards defensive play with resource generation
**Thematic**: Protecting the community provides strength and resolve

### 4. Fermentation System (Signature Mechanic)

**Effect**: Cards marked "Fermented X" gain bonus effects after being held in hand for X turns.
**Implementation**:

- Track turns held for each card in hand
- Apply bonus effects when fermentation threshold reached
- Cards maintain fermentation status until played
**Strategy**: Encourages patience and hand management over aggressive tempo

## Complete Card List (12 Total)

### Fermentation Cards (4 cards)

#### 1. Aged Whiskey

- **Cost**: 2 Energy
- **Category**: Attack
- **Effect**: Deal 8 damage. Fermented 2: Deal +6 damage (14 total).
- **Copies in Deck**: 1
- **Purpose**: Rewards patience with significant damage scaling

#### 2. Vintage Wine

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 4 Block. Fermented 3: Gain +8 Block and heal 3 Health.
- **Copies in Deck**: 1
- **Purpose**: Defensive option that becomes excellent healing/protection

#### 3. Homebrew

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 1 Energy. Fermented 1: Gain 2 Energy instead.
- **Copies in Deck**: 2
- **Purpose**: Energy generation that doubles with minimal patience

#### 4. Nightcap

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: End your turn. Gain 6 Block. Fermented 2: Gain +4 Block and heal 2.
- **Copies in Deck**: 1
- **Purpose**: Turn-ending defensive option with fermentation upside

### Defense-Focused Cards (4 cards)

#### 5. Bar Fortification

- **Cost**: 2 Energy
- **Category**: Skill
- **Effect**: Gain 12 Block. Next turn, gain 6 Block.
- **Copies in Deck**: 1
- **Purpose**: Massive defensive option with persistent protection

#### 6. Bouncer's Presence

- **Cost**: 2 Energy
- **Category**: Power
- **Effect**: At the start of each turn, gain 3 Block.
- **Copies in Deck**: 1
- **Purpose**: Persistent defensive power scaling

#### 7. Last Call

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 8 Block. Draw 1 card. Exhaust.
- **Copies in Deck**: 1
- **Purpose**: Strong defense with card draw but limited use

#### 8. Smooth Talk

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 5 Block. Enemy deals -3 damage next attack.
- **Copies in Deck**: 1
- **Purpose**: Defensive option that weakens enemy offense

### Energy Generation Cards (2 cards)

#### 9. Free Drinks

- **Cost**: 0 Energy
- **Category**: Skill
- **Effect**: Gain 1 Energy. Both you and enemy heal 2 Health.
- **Copies in Deck**: 2
- **Purpose**: Energy gain with thematic mutual benefit

#### 10. Happy Hour

- **Cost**: 2 Energy
- **Category**: Skill
- **Effect**: Gain 2 Energy. All cards cost 1 less this turn (minimum 0).
- **Copies in Deck**: 1
- **Purpose**: Explosive turn enabler with cost reduction

### High-Cost Power Cards (2 cards)

#### 11. Pub Brawl

- **Cost**: 3 Energy
- **Category**: Attack
- **Effect**: Deal 15 damage. Gain 6 Block.
- **Copies in Deck**: 1
- **Purpose**: Expensive but powerful combination of offense and defense

#### 12. House Rules

- **Cost**: 3 Energy
- **Category**: Power
- **Effect**: Your Defense cards heal you for half their Block value.
- **Copies in Deck**: 1
- **Purpose**: Late-game power that transforms defense into sustain

## Why Publican is Excellent as Power Specialist

### Development Advantages

1. **No New Systems Required**: Uses existing Energy, Block, Power, and Exhaust mechanics
2. **Clear Mechanical Identity**: Defense + patience creates distinct playstyle from other classes
3. **Incremental Complexity**: Fermentation adds depth without requiring complex subsystems
4. **Balanced Resource Management**: Energy focus complements existing economy systems

### Player Benefits

1. **Strategic Depth**: Fermentation timing creates meaningful hand management decisions
2. **Multiple Paths to Victory**: Can win through persistence, big turns, or defensive grinding
3. **Satisfying Scaling**: Watching fermented cards grow stronger provides clear progression
4. **Forgiving Playstyle**: High defense and healing options allow recovery from mistakes

### Technical Benefits

1. **Simple Implementation**: Fermentation only requires turn tracking per card in hand
2. **Performance Friendly**: No complex calculations or RNG systems required
3. **Easy Testing**: Deterministic effects make verification straightforward
4. **Minimal UI Requirements**: Turn counters on cards are visually simple

### Class Balance

The Publican provides strategic counterplay to aggressive classes:

- **vs Bushranger**: Defense counters aggression, patience beats tempo
- **vs Prospector**: Consistent energy beats risky RNG, healing counters damage
- **vs Tracker**: Immediate defensive effects counter setup-dependent strategies

### Thematic Coherence

Every mechanic reinforces the community leader fantasy:

- **Energy generation**: Providing sustenance and support
- **Defense focus**: Protecting the community from threats
- **Fermentation**: Patience and craft mastery rewarded
- **High-cost effects**: Business owner's resources enable powerful actions

The Publican offers a unique "defensive engine" playstyle that rewards patience and resource management while maintaining the Australian frontier theme. The fermentation mechanic provides engaging decision-making without system complexity, making it an excellent addition to the class roster.
