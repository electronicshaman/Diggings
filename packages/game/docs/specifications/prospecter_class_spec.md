# Prospector Class Specification

## Character Overview

The **Prospector** represents the archetypal gold seeker - an independent fortune hunter driven by dreams of striking it rich. They embody the risk/reward nature of speculation and gambling that defined the gold rush era.

### Historical Context
- **Time Period**: 1850s-1890s Australian Gold Rush
- **Social Role**: Independent miners, claim owners, fortune seekers
- **Economic Position**: Working class with entrepreneurial aspirations
- **Cultural Identity**: Mix of British, Irish, Chinese, and other immigrants seeking fortune

## Mechanical Identity

### Core Specialization
- **Primary Category**: **Fortune** (70% of deck)
- **Playstyle**: High-variance risk/reward gameplay
- **Resource Focus**: Gold as both currency and strategic resource
- **Signature Mechanic**: **Gold Rush** - Fortune effects compound and improve each other

### Starting Statistics
```
Health: 45/45        # Below average (risky lifestyle takes toll)
Sanity: 110/110      # Above average (optimistic dreamer mindset) 
Energy: 3/3          # Standard energy per turn
Gold: 25             # Above average starting wealth (investment capital)
Corruption: 0        # Starts clean, but fortune comes with price
```

## Class Mechanics

### 1. Gold Rush (Core Passive)
**Effect**: Each Fortune card played this combat increases the effectiveness of subsequent Fortune cards by 1.
**Implementation**: 
- Track `fortune_streak` counter in combat
- Each Fortune card increments counter before resolving
- Counter applies as bonus to success rates, damage, healing, or other effects
- Resets at end of combat

### 2. Risk Tolerance (Active Ability)
**Effect**: Can spend 10 Sanity to reroll any Fortune card effect once per turn.
**Strategy**: Allows pushing luck when stakes are high
**Cost**: Meaningful sanity investment prevents spam usage

### 3. Claim Bonus (Passive)
**Effect**: Gain +2 Gold from all successful Fortune effects.
**Flavor**: Prospector knows how to extract maximum value from lucky strikes

### 4. Prospector's Eye (Information Advantage)
**Effect**: Can see the top card of deck after playing a Fortune card.
**Strategy**: Helps plan future plays and assess risks

## Complete Card List (20 Total)

### Basic Cards (7 cards)

#### 1. Pan for Gold
- **Cost**: 0 Energy
- **Category**: Fortune  
- **Effect**: 50% chance to gain 3 Gold, 50% chance to gain 1 Gold
- **Copies in Deck**: 3
- **Purpose**: Reliable, low-risk fortune generation

#### 2. Pickaxe Strike  
- **Cost**: 1 Energy
- **Category**: Attack
- **Effect**: Deal 6 damage. If you have 20+ Gold, deal +3 damage.
- **Copies in Deck**: 2
- **Purpose**: Basic attack that scales with wealth

#### 3. Steady Hands
- **Cost**: 1 Energy  
- **Category**: Skill
- **Effect**: Gain 5 Block. Next Fortune card this turn has +20% success chance.
- **Copies in Deck**: 2
- **Purpose**: Defensive option that enables gambling

### Signature Fortune Cards (8 cards)

#### 4. Strike It Rich
- **Cost**: 2 Energy
- **Category**: Fortune
- **Effect**: 60% chance: Gain 15 Gold and draw 1 card. 40% chance: Lose 5 Health.
- **Copies in Deck**: 2
- **Purpose**: Core high-risk, high-reward gamble

#### 5. Double or Nothing  
- **Cost**: 1 Energy
- **Category**: Fortune  
- **Effect**: Risk all current Gold. 70% chance to double it, 30% chance to lose it all.
- **Copies in Deck**: 1
- **Purpose**: Ultimate gambling card for desperate situations

#### 6. Prospector's Instinct
- **Cost**: 1 Energy
- **Category**: Fortune
- **Effect**: Look at next 3 cards, choose 1 to draw. 50% chance to not exhaust.
- **Copies in Deck**: 2
- **Purpose**: Information advantage and deck manipulation

#### 7. Lucky Nugget
- **Cost**: 3 Energy
- **Category**: Fortune
- **Effect**: 40% chance: Gain 25 Gold and 10 Health. 60% chance: Gain 2 Corruption.
- **Copies in Deck**: 1  
- **Purpose**: Powerful late-game gamble with corruption risk

#### 8. Miner's Luck
- **Cost**: 1 Energy
- **Category**: Fortune
- **Effect**: Flip 3 coins. Gain benefits based on results: 1 heads = Draw 1, 2 heads = Gain 8 Gold, 3 heads = Deal 12 damage.
- **Copies in Deck**: 1
- **Purpose**: Multiple escalating outcomes

#### 9. Claim Jumping
- **Cost**: 2 Energy
- **Category**: Fortune
- **Effect**: 65% chance: Gain Gold equal to enemy's missing Health. 35% chance: Enemy gains Strength.
- **Copies in Deck**: 1
- **Purpose**: Risk/reward that scales with combat progress

### Support Cards (5 cards)

#### 10. Tool Maintenance
- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Next card played costs 1 less Energy and has improved effects.
- **Copies in Deck**: 1
- **Purpose**: Enabler for expensive Fortune cards

#### 11. Campfire Rest
- **Cost**: 2 Energy
- **Category**: Skill  
- **Effect**: Heal 8 Health and 5 Sanity. If you have less than 10 Gold, heal +5 more Health.
- **Copies in Deck**: 1
- **Purpose**: Recovery option that helps when luck runs bad

#### 12. Bush Telegraph  
- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Learn enemy's next intent. If it's an Attack, gain 6 Block.
- **Copies in Deck**: 1
- **Purpose**: Information and conditional defense

#### 13. Swagman's Wisdom
- **Cost**: 2 Energy
- **Category**: Skill
- **Effect**: Draw 2 cards. If both are same type, draw 1 more and gain 3 Gold.
- **Copies in Deck**: 1
- **Purpose**: Card draw with fortune bonus potential

#### 14. Claim Stake
- **Cost**: 1 Energy
- **Category**: Skill
- **Effect**: Gain 4 Block. Gain +2 Block for each Fortune card played this combat.
- **Copies in Deck**: 1
- **Purpose**: Defensive scaling with class specialty

## Prospector Build Archetypes

### 1. High Roller (Aggressive Gambling)
**Strategy**: Play maximum Fortune cards, accept high variance
**Key Cards**: Strike It Rich, Double or Nothing, Lucky Nugget
**Pros**: Highest potential rewards, exciting gameplay
**Cons**: Can lose quickly to bad luck, sanity management issues

### 2. Calculated Risk (Controlled Gambling)  
**Strategy**: Use information and setup cards to improve odds
**Key Cards**: Prospector's Instinct, Steady Hands, Bush Telegraph
**Pros**: More consistent than High Roller, strategic depth
**Cons**: Slower than pure aggression, setup dependent

### 3. Gold Hoarder (Economic Engine)
**Strategy**: Accumulate gold steadily, use wealth for advantages
**Key Cards**: Pan for Gold, Pickaxe Strike (conditional), Tool Maintenance
**Pros**: Reliable progression, strong scaling effects
**Cons**: Less exciting, vulnerable to forced spending

### 4. Corruption Dancer (Risk Everything)
**Strategy**: Accept corruption for power, use sanity as resource
**Key Cards**: Lucky Nugget, Risk Tolerance ability, high-cost gambles
**Pros**: Access to most powerful effects
**Cons**: Requires careful resource management, can spiral quickly

## Balance Considerations

### Power Level
- **Early Game**: Moderate (45 health is below average)
- **Mid Game**: High variance (great runs vs terrible runs)
- **Late Game**: Potentially strongest (if luck and resource management good)

### Skill Floor vs Ceiling
- **Skill Floor**: Medium (Fortune mechanics require understanding probability)
- **Skill Ceiling**: High (resource management, risk assessment, timing crucial)

### Counterplay Patterns
- **Enemies with Gold Steal**: Forces defensive play
- **Sanity Damage Enemies**: Limits Risk Tolerance usage  
- **Block-Heavy Enemies**: Reduces value of damage-based fortunes
- **Fast Enemies**: Pressure prevents setup time

## Upgrade Paths

### Card Upgrades
- **Pan for Gold+**: Guarantees minimum 2 Gold (removes total failure)
- **Strike It Rich+**: Improves to 70% chance (better risk profile)  
- **Prospector's Instinct+**: Always draws the chosen card (removes exhaust chance)
- **Double or Nothing+**: Can target specific resource (Gold, Health, Energy)

### Character Unlocks (Post-MVP)
- **Lucky Charm**: Start each combat with +10% Fortune success rate
- **Midas Touch**: Convert one random card to Gold-type each combat
- **Fortune Favors Bold**: Deal +1 damage for each Fortune card in hand

## Thematic Integration

### Flavor Elements
- **Card Art**: Mining tools, gold nuggets, prospector equipment
- **Sound Effects**: Pickaxe strikes, gold clinking, dice rolling
- **Dialogue**: Optimistic gold rush slang, references to "the big strike"

### Story Events (Future)
- **Rich Vein Discovery**: Special fortune card opportunities
- **Claim Dispute**: Risk gold to avoid combat or fight for bigger reward
- **Traveling Merchant**: Spend gold for temporary cards/effects
- **Ghost Town**: Abandoned claims with risks and rewards

## Implementation Priority

### Phase 1 (Current): Core Fortune System
1.  Basic Fortune cards implemented
2. = Gold Rush mechanic implementation  
3. =Ë Risk Tolerance ability implementation
4. =Ë Balance testing with existing enemies

### Phase 2: Complete Card Set
1. Implement remaining 15 cards
2. Test all Fortune interactions
3. Verify upgrade paths work
4. Polish card descriptions and effects

### Phase 3: Advanced Features  
1. Character unlock system
2. Prospector-specific events
3. Cross-class synergy testing
4. Advanced build archetype support

The Prospector provides a unique risk/reward gameplay experience that distinguishes it from typical card battler classes, while maintaining thematic authenticity to the gold rush setting and integrating properly with the theme-agnostic core system.