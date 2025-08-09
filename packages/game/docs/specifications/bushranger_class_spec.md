# Bushranger Class Specification

## Character Overview

The **Bushranger** represents the archetypal Australian outlaw - a hardened fighter forced into banditry by circumstances, survival, or injustice. They embody aggressive, direct combat with a focus on speed, momentum, and overwhelming firepower.

### Historical Context

- **Time Period**: 1850s-1890s Australian Colonial Era
- **Social Role**: Outlaws, bandits, bush warriors, escaped convicts
- **Economic Position**: Living outside society, surviving through robbery and violence
- **Cultural Identity**: Often Irish rebels, wrongly accused, or victims of harsh colonial justice

## Mechanical Identity

### Core Specialization

- **Primary Category**: **Attack** (70% of deck)
- **Playstyle**: Aggressive, fast-paced, high damage output
- **Resource Focus**: Ammo management and momentum building
- **Signature Mechanic**: **Outlaw's Edge** - Stronger when desperate or outnumbered

### Starting Statistics

```txt
Health: 55/55        # Above average (tough, hardened fighter)
Sanity: 90/90        # Below average (outlaw stress, trauma)
Energy: 3/3          # Standard energy per turn
Gold: 10             # Below average (living rough, no legitimate income)
Corruption: 0        # Starts clean but violence corrupts
```

## Class Mechanics

### 1. Outlaw's Edge (Core Passive)

**Effect**: Deal +2 damage when Health is below 50%. Deal +1 additional damage for each enemy beyond the first.
**Implementation**:

- Check health percentage before damage calculation
- Count active enemies in combat
- Apply bonuses to all Attack cards
**Strategy**: Rewards aggressive play and creates comeback potential

### 2. Quick Draw (Active Ability)

**Effect**: First Attack card played each turn costs 1 less Energy (minimum 0).
**Strategy**: Enables faster starts and more aggressive turns
**Flavor**: Lightning-fast gunslinger reflexes

### 3. Wanted Status (Risk/Reward Passive)

**Effect**: Take +1 damage from all sources, but gain +3 Gold from victories.
**Balance**: Higher risk for better economic rewards
**Thematic**: Being wanted makes you a target but bounties are lucrative

### 4. Ammo System (Resource Management)

**Effect**: Many Bushranger cards use Ammo instead of or in addition to Energy.
**Starting Ammo**: 6 rounds per combat
**Reload Mechanics**: Specific cards restore Ammo during combat

## Complete Card List (20 Total)

### Basic Cards (7 cards)

#### 1. Quick Shot

- **Cost**: 1 Energy
- **Category**: Attack
- **Effect**: Deal 4 damage. If first card played this turn, draw 1 card.
- **Copies in Deck**: 3
- **Purpose**: Fast, efficient damage with tempo bonus

#### 2. Take Cover

- **Cost**: 1 Energy  
- **Category**: Skill
- **Effect**: Gain 6 Block. If Health below 50%, gain +2 Block.
- **Copies in Deck**: 2
- **Purpose**: Defensive option that scales with desperation

#### 3. Reload

- **Cost**: 0 Energy
- **Category**: Skill
- **Effect**: Gain 3 Ammo. Draw 1 card.
- **Copies in Deck**: 2
- **Purpose**: Ammo management and card cycling

### Signature Attack Cards (8 cards)

#### 4. Six-Shooter

- **Cost**: 1 Energy + 1 Ammo
- **Category**: Attack
- **Effect**: Deal 8 damage. Quick Draw: Deal +2 damage.
- **Copies in Deck**: 2
- **Purpose**: Core ammo-based attack with Quick Draw synergy

#### 5. Fan the Hammer

- **Cost**: 2 Energy
- **Category**: Attack
- **Effect**: Deal 3 damage per Ammo. Consume all Ammo.
- **Copies in Deck**: 1
- **Purpose**: High-risk burst damage, ammo dump

#### 6. Ambush Strike

- **Cost**: 2 Energy
- **Category**: Attack
- **Effect**: Deal 15 damage if first card played this turn, otherwise deal 6 damage.
- **Copies in Deck**: 1
- **Purpose**: Powerful opening that rewards planning

#### 7. Desperado's Gambit

- **Cost**: 1 Energy
- **Category**: Attack  
- **Effect**: Deal damage equal to missing Health. Gain 1 Ammo.
- **Copies in Deck**: 1
- **Purpose**: Scaling attack that gets stronger as you get weaker

#### 8. Bounty Shot

- **Cost**: 1 Energy + 1 Ammo
- **Category**: Attack
- **Effect**: Deal 6 damage. If this kills the enemy, gain 8 Gold.
- **Copies in Deck**: 2
- **Purpose**: Economic incentive for finishing enemies

#### 9. Wild Shot

- **Cost**: 1 Energy + 1 Ammo  
- **Category**: Attack
- **Effect**: Deal 4-10 damage (random). If max damage, don't consume Ammo.
- **Copies in Deck**: 1
- **Purpose**: Variable damage with potential ammo refund

### Support Cards (5 cards)

#### 10. Outlaw's Intuition

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: See enemy's next intent. If it's an Attack intent, gain 2 Ammo and 3 Block.
- **Copies in Deck**: 1  
- **Purpose**: Information advantage with defensive/offensive benefits

#### 11. Bush Survival

- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Heal 6 Health. If Health below 25%, heal +6 more.
- **Copies in Deck**: 1
- **Purpose**: Emergency healing that's better when desperate

#### 12. Wanted Poster

- **Cost**: 0 Energy
- **Category**: Skill
- **Effect**: Draw 2 cards. Take 2 damage at end of turn.
- **Copies in Deck**: 1
- **Purpose**: Card draw with thematic drawback

#### 13. Bandit's Code

- **Cost**: 2 Energy
- **Category**: Power
- **Effect**: At start of each turn, if you have 2+ Ammo, deal 3 damage to enemy.
- **Copies in Deck**: 1
- **Purpose**: Persistent pressure that rewards ammo management

#### 14. Last Stand

- **Cost**: 2 Energy
- **Category**: Power  
- **Effect**: When you would take fatal damage, instead go to 1 Health and gain 4 Ammo.
- **Copies in Deck**: 1
- **Purpose**: Dramatic comeback mechanic with thematic flavor

## Why Bushranger is Good Starting Class

### Development Advantages

1. **Simpler Mechanics**: Attack specialization is more straightforward than Fortune gambling
2. **Clear Power Fantasy**: "Shoot things until they die" is immediately understandable  
3. **Linear Scaling**: Damage bonuses are easier to balance than variable outcomes
4. **Less Complex Interactions**: Ammo is simpler than multi-step gambling mechanics

### Player Benefits

1. **New Player Friendly**: Aggressive strategy is intuitive
2. **Clear Win Condition**: Deal damage, reduce enemy health to zero
3. **Immediate Feedback**: Damage numbers provide instant satisfaction
4. **Forgiving**: High health pool allows learning from mistakes

### Technical Benefits

1. **Fewer Edge Cases**: Attack cards have fewer conditional branches than Fortune cards
2. **Easier Testing**: Damage outcomes are predictable and verifiable  
3. **Simple UI**: Ammo counter is straightforward compared to gambling probability displays
4. **Performance**: Less RNG calculation overhead than Fortune mechanics

The Bushranger provides a solid foundation for testing the core combat system while offering engaging but straightforward mechanics. Once the Attack specialization is fully implemented and balanced, it creates a template for the other classes while giving players an immediately satisfying aggressive playstyle.
