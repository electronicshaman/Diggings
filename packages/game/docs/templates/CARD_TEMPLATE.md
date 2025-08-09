# Card Template

## Card Creation Checklist

Use this template when creating new cards for the card battler prototype. Each card must fit within the theme-agnostic mechanical framework while providing flavorful theming.

## Basic Information

### Required Fields
- **Card Name**: [Descriptive, thematic name]
- **Energy Cost**: [0-5, with 1-2 being most common]
- **Sanity Cost**: [Usually 0, non-zero for corrupted/dangerous cards]  
- **Card Type**: [Theme-specific: Gold/Grit/Grog/Gamble]
- **Mechanical Category**: [Theme-agnostic: Attack/Skill/Power/Fortune]
- **Card Handling**: [Standard/Equipped/Flash/Keep/Spent]

### Descriptive Fields
- **Description**: [Clear, concise effect description] 
- **Flavor Text**: [Optional thematic flavor]

## Card Effects System

### Effect Structure
Each card contains an array of `CardEffect` resources that define what the card does.

#### Common Effect Types
```gdscript
# Damage effects
Damage.gd - Deal direct damage to enemy
MultipleDamage.gd - Deal damage multiple times
MissingHealthDamage.gd - Damage based on missing health
EnemyMissingHealthDamage.gd - Damage based on enemy missing health

# Defense effects  
Defense.gd - Gain block/defense
Heal.gd - Restore health
SanityRestore.gd - Restore sanity

# Utility effects
Draw.gd - Draw additional cards
DeckManipulation.gd - Modify deck contents
CostReduction.gd - Reduce costs of other cards

# Fortune effects
Gambling.gd - Risk/reward mechanics
LuckyStreak.gd - Escalating effects
RandomCard.gd - Generate random cards

# Power effects (persistent)
PermanentEnergy.gd - Increase max energy
HealingBonus.gd - Improve healing effects
NextCardDiscount.gd - Affect next card played
```

## Card Template by Mechanical Category

### Attack Cards (Direct Damage)

**Purpose**: Deal damage to enemies, potentially with secondary utility

```gdscript
# Template: Basic Attack Card
card_name = "Strike Type Name"
energy_cost = 1
sanity_cost = 0
card_type = "Gold"  # (or theme equivalent)
mechanical_category = "Attack" 
card_handling = "Standard"
description = "Deal X damage."

# Effects array
effects = [
    Damage.new(damage_amount: 6)  # Standard 1-energy damage
]
```

**Guidelines:**
- Energy cost 1 = 6-8 damage
- Energy cost 2 = 10-14 damage  
- Energy cost 3+ = 15+ damage with drawbacks or conditions
- Can include minor secondary effects (draw 1, gain 2 block)

### Skill Cards (Utility & Defense)

**Purpose**: Defense, card manipulation, buffs/debuffs, resource management

```gdscript
# Template: Basic Defense Card
card_name = "Shield Type Name" 
energy_cost = 1
sanity_cost = 0
card_type = "Grit"  # (or theme equivalent)
mechanical_category = "Skill"
card_handling = "Standard"
description = "Gain X block."

# Effects array  
effects = [
    Defense.new(defense_amount: 8)  # Standard 1-energy defense
]
```

**Guidelines:**
- Energy cost 1 = 6-8 block or equivalent utility
- Focus on survival, positioning, resource management
- Can manipulate hand, deck, or game state
- Should not deal direct damage (indirect damage through debuffs OK)

### Power Cards (Persistent Effects)

**Purpose**: Ongoing effects that last the entire combat encounter

```gdscript
# Template: Basic Power Card
card_name = "Power Type Name"
energy_cost = 2  
sanity_cost = 0
card_type = "Grog"  # (or theme equivalent)  
mechanical_category = "Power"
card_handling = "Standard"
description = "Ongoing effect description."

# Effects array
effects = [
    PermanentEnergy.new(energy_bonus: 1)  # Example persistent effect
]
```

**Guidelines:**
- Usually cost 2-3 energy (significant investment)
- Only one copy can be active per combat
- Effects last entire encounter
- Should provide meaningful ongoing advantage
- Balance power with energy investment

### Fortune Cards (Risk/Reward)

**Purpose**: Variable outcomes, gambling mechanics, luck-based effects

```gdscript
# Template: Basic Fortune Card
card_name = "Fortune Type Name"
energy_cost = 1
sanity_cost = 0  
card_type = "Gamble"  # (or theme equivalent)
mechanical_category = "Fortune"
card_handling = "Standard"
description = "Variable effect with risk/reward."

# Effects array
effects = [
    Gambling.new(
        success_effect: "gain 10 gold",
        failure_effect: "lose 5 health", 
        success_chance: 0.7
    )
]
```

**Guidelines:**
- Higher risk should provide higher potential reward
- Failed gambles should have meaningful consequences
- Success rates typically 50-80% depending on reward
- Can affect resources outside of combat (gold, corruption)

## Card Handling Types

### Standard
- **Behavior**: Normal card behavior - plays, goes to discard pile
- **When to use**: Most cards should be Standard

### Equipped  
- **Behavior**: Starts in hand instead of deck
- **When to use**: Tools, weapons, persistent items character always has

### Flash
- **Behavior**: Triggers effect immediately when drawn
- **When to use**: Inspiration, revelations, involuntary reactions

### Keep
- **Behavior**: Doesn't discard at end of turn if unplayed
- **When to use**: Defensive options, insurance cards

### Spent  
- **Behavior**: Removed from game after one use
- **When to use**: Powerful one-shot effects, consumables

## Balance Guidelines

### Energy Cost Standards
```
0 Energy: Weak effects, often with drawbacks or conditions
1 Energy: Standard backbone effects (6-8 damage/block)
2 Energy: Strong tactical effects (12+ damage, significant utility)  
3 Energy: Powerful effects requiring build-around
4+ Energy: Game-changing effects with major commitment
```

### Effect Power Levels
```
Damage per Energy: ~6-8 points
Block per Energy: ~6-8 points  
Card Draw per Energy: ~1-2 cards
Healing per Energy: ~4-6 health
```

### Risk/Reward Balance
- High-risk gambles should offer 2-3x standard effect on success
- Failed gambles should cost ~25-50% of potential gain
- Corruption effects should provide power at sanity cost

## Implementation Steps

### 1. Create Card Resource File
```
data/cards/{category}/{card-name}.tres
```

### 2. Fill Basic Properties
- Set card_name, energy_cost, description
- Choose appropriate card_type and mechanical_category
- Select card_handling behavior

### 3. Configure Effects Array
- Add CardEffect resources for desired behavior
- Set effect parameters (damage amounts, etc.)
- Test effect interactions

### 4. Balance Testing
- Test in actual gameplay scenarios
- Adjust costs and effects based on player experience
- Consider interactions with other cards

### 5. Polish
- Write compelling flavor text
- Ensure description clarity
- Add to appropriate character decks if needed

## Example: Complete Card Implementation

### "Prospector's Strike" (Attack Card)

```gdscript
# Resource file: data/cards/attack/prospectors-strike.tres
card_name = "Prospector's Strike"
energy_cost = 1
sanity_cost = 0
card_type = "Gold"
mechanical_category = "Attack"  
card_handling = "Standard"
description = "Deal 7 damage. If you have 20+ Gold, deal 3 additional damage."
flavor_text = "Hard work pays off, but luck pays better."

effects = [
    Damage.new(
        damage_amount: 7,
        conditional_bonus: 3,
        condition_type: "player_gold",
        condition_value: 20
    )
]
```

This card demonstrates:
-  Standard attack damage for 1 energy (7)
-  Thematic gold-based condition
-  Clear, concise description
-  Appropriate for Prospector character
-  Balanced risk/reward (gold investment for damage bonus)

## Quality Checklist

Before finalizing a card, verify:

- [ ] **Theme Consistency**: Fits character class and world setting
- [ ] **Mechanical Clarity**: Effect is immediately understandable
- [ ] **Balance Appropriate**: Cost matches effect power level
- [ ] **Synergy Potential**: Works well with class specialization  
- [ ] **Unique Identity**: Feels different from existing cards
- [ ] **Implementation Ready**: All required fields completed
- [ ] **Tested**: Played in actual game scenarios

This template ensures all cards maintain quality standards while providing creative flexibility for themed content creation.