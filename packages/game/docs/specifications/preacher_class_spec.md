# Preacher Class Specification

## Implementation Status: ✅ Resource Created

The Preacher character resource has been implemented at `data/characters/preacher.tres` with full class mechanics, abilities, and card accessibility rules defined.

## Character Overview

The **Preacher** represents the spiritual frontier of gold rush settlements - a figure wielding faith as both weapon and curse. They embody the duality of genuine belief and cynical exploitation, converting the desperate's hopes into power through prayers, miracles, and dark bargains.

### Historical Context

- **Time Period**: 1850s-1890s Australian Colonial Era
- **Social Role**: Frontier preachers, missionaries, spiritual con artists, tent revivalists
- **Economic Position**: Dependent on congregation donations, operating between poverty and prosperity
- **Cultural Identity**: Bringing religion (and exploitation) to goldfield settlements; represents both salvation and damnation

## Mechanical Identity

### Core Specialization

- **Primary Category**: **Fortune** (faith-based gambling with consequences)
- **Secondary Focus**: **Risk/Reward** (corruption and sanity costs)
- **Playstyle**: Faith accumulation, strategic spending, managing the line between holy power and dark corruption
- **Resource Focus**: Faith as currency - build it up, spend it for power
- **Signature Mechanic**: **Faith System** - unique resource that scales attacks and enables powerful effects

### Starting Statistics

```text
Health: 48/48        # Below average (spiritual focus over physical)
Sanity: 100/100      # Standard (balanced between faith and doubt)
Energy: 3/3          # Standard energy per turn
Gold: 12             # Low (worldly wealth matters less than faith)
Corruption: 0        # Starts clean but dark bargains beckon
```

Last verified: 2025-01-04

## Implementation Snapshot (data/characters/preacher.tres)

- mechanical_specialization: Fortune
- base_health: 48, base_sanity: 100, base_energy: 3, starting_gold: 12
- starting_deck_resource: preacher_starter.tres; starting_deck_size: 12
- passive_abilities: ["Fervent Faith", "Holy Conviction", "Temptation"]
- active_abilities: ["Crisis of Faith"]
- unique_resources: ["Faith"]
- preferred_card_types: ["Faith"], forbidden_card_types: []
- unlocked_by_default: false
- unlock_requirements: ["complete_run_with_prospector"]

## Deltas vs Spec

- None significant. Uses starting_deck_resource (consistent with other classes).

## Class Mechanics

### 1. Fervent Faith (Core Passive)

**Effect**: Start each combat with 2 Faith. At the start of each turn, gain 1 Faith (maximum 10).
**Implementation**:

- Initialize Faith to 2 at combat start
- Add 1 Faith at turn start, capped at 10
- Track Faith as a combat resource like Ammo
**Strategy**: Provides baseline Faith generation for card synergies
**Flavor**: Unwavering belief that grows stronger through adversity

### 2. Holy Conviction (Scaling Passive)

**Effect**: Attack cards deal +1 bonus damage for every 3 Faith you have (rounded down).
**Implementation**:

- Check Faith count before attack damage calculation
- Apply bonus: floor(Faith / 3) extra damage
**Strategy**: Rewards accumulating Faith before attacking
**Flavor**: Righteous fury made manifest through pure belief

### 3. Temptation (Risk/Reward Passive)

**Effect**: Whenever you spend Faith, if Faith drops to 0, gain 1 Corruption. Cards with "Eldritch" or "Forbidden" in their name grant +1 extra Faith but cost 1 Sanity.
**Implementation**:

- Monitor Faith changes; trigger on reaching 0 from above
- Check card names for keywords and apply bonuses/costs
**Strategy**: Creates tension between spending Faith (power) and conserving it (avoiding corruption)
**Flavor**: The line between holy power and dark bargains grows thin

### 4. Crisis of Faith (Active Ability)

**Effect**: Once per combat, exhaust all Faith to deal damage equal to 2x the Faith spent to all enemies. Gain 2 Corruption.
**Implementation**:

- Usable once per combat (track usage flag)
- Calculate damage as 2 * current Faith
- Set Faith to 0, add 2 Corruption
- Apply damage to all enemies
**Strategy**: Devastating finisher that resets your Faith economy
**Flavor**: A moment of terrible doubt unleashes destructive power

## Complete Card List (15 Total)

### Attack Cards (4 cards)

#### 1. Fire and Brimstone

- **Cost**: 1 Energy
- **Category**: Attack
- **Effect**: Deal 5 damage. If Faith >= 3, deal +3 bonus damage.
- **Copies in Deck**: 2
- **Purpose**: Core attack with Faith threshold bonus

#### 2. Eldritch Sermon

- **Cost**: 1 Energy
- **Category**: Attack
- **Effect**: Deal 6 damage. Enemy loses 3 Sanity. Gain 1 Faith.
- **Copies in Deck**: 1
- **Purpose**: Damage + sanity pressure + Faith generation (Lovecraftian synergy)

#### 3. Righteous Fury

- **Cost**: 2 Energy
- **Category**: Attack
- **Effect**: Spend 4 Faith. Deal 20 damage that ignores enemy defense.
- **Copies in Deck**: 1
- **Purpose**: High-cost finisher that bypasses block, requires Faith investment

#### 4. Damnation

- **Cost**: 3 Energy
- **Category**: Attack
- **Effect**: Spend 8 Faith. Deal 35 damage. If this kills the enemy, gain 10 Gold. Otherwise, lose all remaining Faith.
- **Copies in Deck**: 1
- **Purpose**: Ultimate attack with massive risk/reward - all-in on the kill

### Skill Cards (5 cards)

#### 5. Psalm of Protection

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 6 Block.
- **Copies in Deck**: 2
- **Purpose**: Basic defensive option

#### 6. Holy Water

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 4 Block. Gain 1 Faith.
- **Copies in Deck**: 2
- **Purpose**: Defense + Faith generation, core economy card

#### 7. Laying on Hands

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Heal 5 HP. If you spend 2 Faith, heal +3 more.
- **Copies in Deck**: 1
- **Purpose**: Healing with optional Faith spend for enhanced effect

#### 8. Martyrdom

- **Cost**: 2 Energy
- **Category**: Skill
- **Effect**: Spend 5 Faith. Take 10 damage. Gain 15 Block. Next turn, gain +2 Energy.
- **Copies in Deck**: 1
- **Purpose**: High-risk setup card - sacrifice now for powerful next turn

#### 9. Missionary Zeal

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Draw 1 card. Gain 1 Faith.
- **Copies in Deck**: 1
- **Purpose**: Cantrip with Faith generation, deck cycling

### Fortune Cards (5 cards)

#### 10. Tent Revival

- **Cost**: 0 Energy
- **Category**: Fortune
- **Effect**: Gain 1 Faith. If Faith is currently 0, gain 2 Faith instead.
- **Copies in Deck**: 2
- **Purpose**: Free Faith generation, recovery when depleted

#### 11. Snake Oil

- **Cost**: 0 Energy
- **Category**: Fortune
- **Effect**: 50% chance: Gain 3 Gold. 50% chance: Lose 2 Sanity.
- **Copies in Deck**: 1
- **Purpose**: Classic con artist gamble, thematic risk/reward

#### 12. Forbidden Tome

- **Cost**: 2 Energy
- **Category**: Fortune
- **Effect**: Gain 5 Faith. Gain 2 Corruption. Draw 2 cards.
- **Copies in Deck**: 1
- **Purpose**: Major Faith spike with corruption cost, Lovecraftian knowledge

#### 13. False Prophet

- **Cost**: 1 Energy
- **Category**: Fortune
- **Effect**: 70% chance: Gain 8 Gold and 2 Faith. 30% chance: Enemy gains 5 Block.
- **Copies in Deck**: 1
- **Purpose**: Economic gambling with congregation exploitation flavor

#### 14. Dark Pact

- **Cost**: 0 Energy
- **Category**: Fortune
- **Effect**: Lose 10 Sanity. Gain 6 Faith.
- **Copies in Deck**: 1
- **Purpose**: Emergency Faith generation at severe sanity cost

### Power Cards (1 card)

#### 15. Testament

- **Cost**: 3 Energy
- **Category**: Power
- **Effect**: At the start of each turn, deal damage to the enemy equal to your current Faith.
- **Copies in Deck**: 1
- **Purpose**: Persistent scaling damage that rewards Faith accumulation

## Why Preacher is Excellent as Faith-Based Fortune Specialist

### Thematic Coherence

Every mechanic reinforces the frontier preacher fantasy:

- **Faith as currency**: Literal spending/gaining of belief as a gameplay resource
- **Corruption consequences**: Dark bargains carry lasting costs
- **Duality theme**: Cards split between holy (Psalm, Holy Water, Laying on Hands) and corrupt (Eldritch Sermon, Forbidden Tome, Dark Pact)
- **Lovecraftian integration**: Eldritch knowledge, forbidden tomes, sanity costs blend faith with cosmic horror

### Mechanical Uniqueness

1. **Only Faith-based class**: Unique resource distinct from Ammo (Bushranger) or Fortune Streak (Prospector)
2. **Risk tied to Corruption/Sanity**: Unlike Prospector's gold gambling, Preacher risks permanent consequences
3. **Scaling through accumulation**: Holy Conviction rewards patience like Publican's Fermentation
4. **Burst potential**: Crisis of Faith provides unique combat-ending option

### Development Advantages

1. **Builds on Fortune framework**: Leverages existing RNG and probability systems from Prospector
2. **New resource type**: Faith adds mechanical variety without complex subsystems
3. **Clear upgrade path**: Cards can scale through Faith thresholds and corruption costs
4. **Testable mechanics**: Faith tracking is deterministic, only Fortune cards use RNG

### Balance Considerations

- **Expert difficulty (4)**: Requires understanding Faith economy and corruption management
- **Low starting gold (12)**: Faith over worldly wealth thematically appropriate
- **Locked class**: Requires Prospector completion to understand Fortune mechanics first
- **Lower HP (48)**: Spiritual focus means less physical durability
- **vs Bushranger**: Different aggression style - build Faith then burst vs. constant pressure
- **vs Prospector**: Different Fortune style - Faith management vs. luck gambling
- **vs Publican**: Both reward patience, but Preacher spends resources while Publican accumulates
- **vs Tracker**: Both have setup mechanics, but Preacher is offense-oriented

### Player Fantasy

The Preacher delivers on multiple power fantasies:

- **Righteous crusader**: Build Faith, smite enemies with holy fury
- **Charismatic con artist**: Exploit the desperate with Snake Oil and False Prophet
- **Dark bargainer**: Trade sanity for power, flirt with corruption
- **Apocalyptic preacher**: Crisis of Faith as dramatic "end times" finisher

The Preacher provides a unique "faith engine" playstyle that rewards resource management and strategic spending while maintaining the Australian frontier meets Lovecraftian horror theme. The Faith mechanic creates engaging tension between accumulation (for scaling) and spending (for power), making it an excellent addition to the class roster.
