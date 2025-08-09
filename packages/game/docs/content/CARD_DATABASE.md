# Card Database

## Current Implementation Status

### Existing Cards (5 total)

#### Attack Cards (Gold Category)
1. **Pickaxe Strike** (1 Energy)
   - Effect: Deal 3 damage
   - File: `data/cards/attack/pickaxe-strike.tres`
   - Status:  Implemented

2. **Dynamite** 
   - File: `data/cards/attack/dynamite.tres`  
   - Status:  Implemented

#### Skill Cards (Grit Category)  
3. **Bush Cover**
   - File: `data/cards/skill/bush-cover.tres`
   - Status:  Implemented

#### Power Cards (Grog Category)
4. **Pub Brawl**
   - File: `data/cards/power/pub-brawl.tres` 
   - Status:  Implemented

#### Fortune Cards (Gamble Category)
5. **Strike It Rich**
   - File: `data/cards/fortune/strike-it-rich.tres`
   - Status:  Implemented

## Planned Card Database Structure

### Prospector Character Cards (Priority)

The Prospector specializes in **Fortune (Gamble)** cards with risk/reward mechanics.

#### Core Prospector Cards (20 total planned)

**Basic Cards (Always Available)**
- **Pan for Gold** (0 Energy) - Basic fortune card, small gold gain
- **Claim Stake** (1 Energy) - Mark territory, defensive positioning  
- **Pickaxe Strike** (1 Energy) - Basic attack using mining tools
- **Steady Hands** (1 Energy) - Basic skill, accuracy bonus

**Fortune/Gamble Specialization (8 cards)**
- **Strike It Rich** (2 Energy) - High reward, high risk gold gain
- **Double or Nothing** (1 Energy) - Risk current gold for potential double
- **Lucky Nugget** (3 Energy) - Massive gold gain with corruption risk
- **Prospector's Instinct** (1 Energy) - Reveal next card, gamble on type
- **Gold Rush Fever** (2 Energy) - Multiple small gambles in sequence  
- **Claim Jumping** (2 Energy) - Steal enemy resources, but risk retaliation
- **Fool's Gold** (0 Energy) - Appears valuable, actually causes problems
- **Miner's Luck** (1 Energy) - Flip coin for bonus effects

**Support Cards (5 cards)**
- **Bush Telegraph** (1 Energy) - Information gathering
- **Campfire Rest** (2 Energy) - Heal health and sanity
- **Tool Maintenance** (1 Energy) - Improve next card played
- **Swagman's Wisdom** (2 Energy) - Draw cards, gain insight
- **Outback Survival** (1 Energy) - Defensive positioning

**Advanced Cards (Unlockable, 3 cards)**
- **Golden Touch** (3 Energy) - Transform cards to gold variants
- **Eureka Moment** (2 Energy) - Massive effect if conditions met
- **Mother Lode** (4 Energy) - Ultimate prospector power

### Card Categories by Mechanical Function

#### Attack Cards (Direct Damage)
- Primary damage dealers
- May have secondary utility effects
- Energy costs: 0-3 typically
- Examples: Pickaxe Strike, Dynamite, Tool Strike

#### Skill Cards (Utility & Defense)  
- Defensive abilities (block, dodge)
- Card manipulation (draw, discard)
- Buff/debuff effects
- Energy costs: 0-2 typically
- Examples: Bush Cover, Steady Aim, Quick Reflexes

#### Power Cards (Persistent Effects)
- Last entire combat encounter
- Only one copy playable per fight
- Ongoing passive effects
- Energy costs: 1-3 typically  
- Examples: Pub Brawl, Mining Expertise, Gold Rush

#### Fortune Cards (RNG/Risk-Reward)
- Variable or chance-based outcomes
- Risk/reward mechanics
- Gambling and speculation themes
- Energy costs: 0-4 range
- Examples: Strike It Rich, Double or Nothing

### Card Rarity System (Planned)

#### Common Cards
- Found frequently during runs
- Form the backbone of decks
- Simple, reliable effects
- Examples: Basic attacks, simple defenses

#### Uncommon Cards  
- Moderate power level
- Interesting but not overwhelming
- Available through normal progression
- Examples: Specialized tools, tactical skills

#### Rare Cards
- Powerful effects with drawbacks
- Build-defining potential
- Found through special events
- Examples: Dangerous gambles, corrupting powers

#### Legendary Cards
- Extremely powerful and unique
- Major risk/reward or complexity
- Single copy per run
- Examples: Cursed artifacts, ultimate abilities

### Card Modification System (Digital-Only)

#### Standard Modifiers
- **+Damage**: Increase damage by 1-3
- **-Cost**: Reduce energy cost by 1  
- **+Effect**: Additional minor effect
- **Evolving**: Gains +1 damage per play

#### Advanced Modifiers  
- **Viral**: Creates copy in deck when played
- **Phasing**: 50% chance to not exist each combat
- **Unstable**: Randomly becomes different card
- **Ethereal**: Exhaust if not played this turn

### Implementation Priority

#### Phase 1: Complete Prospector (Current Focus)
1. Implement all 20 Prospector cards
2. Ensure all Fortune mechanics work properly
3. Balance testing and iteration
4. Complete card art and flavor text

#### Phase 2: Expand Other Classes
1. **Bushranger** (Attack specialist) - 20 cards
2. **Tracker** (Skill specialist) - 20 cards  
3. **Publican** (Power specialist) - 20 cards

#### Phase 3: Neutral & Advanced Cards
1. Neutral cards usable by all classes
2. Cross-class combination cards
3. Advanced/corrupted variants
4. Event-specific cards

### Technical Implementation

#### Card Data Structure (Updated)
```gdscript
# CardData.gd
extends Resource
class_name CardData

@export var card_name: String
@export var energy_cost: int
@export var sanity_cost: int = 0
@export var description: String  
@export var flavor_text: String
@export var card_type: String          # Theme-specific (Gold/Grit/Grog/Gamble)
@export var card_handling: String      # Behavioral rules
@export var effects: Array[CardEffect]
@export var modifiers: Array[String] = []

# Character class relationships (NEW)
@export_group("Class Accessibility")
@export var class_affinity: Array[String] = []  # Empty = all classes, populated = restricted
@export var accessibility_tier: String = "Neutral"  # Starting/Class/Neutral/Rare
@export var mechanical_category: String = "Attack"  # Attack/Skill/Power/Fortune
```

#### Card Accessibility System
- **Starting Cards**: Appear in character starting decks only
- **Class Cards**: Character-specific cards found during runs
- **Neutral Cards**: Available to all characters
- **Rare Cards**: Special cards with limited availability

#### Class Affinity System
- Cards can be restricted to specific character classes
- Empty `class_affinity` array means all classes can use the card
- Populated array restricts card to listed classes only
- Characters have `preferred_card_types` and `forbidden_card_types`

#### Card Effect System
- Each card has array of CardEffect resources
- Effects resolved through CardEffects system  
- Stackable and modifiable effects
- Data-driven effect parameters

### Balance Guidelines

#### Energy Costs
- **0 Energy**: Weak effects, often with drawbacks
- **1 Energy**: Standard effects, deck backbone  
- **2 Energy**: Strong effects, tactical choices
- **3+ Energy**: Powerful effects, build-around cards

#### Fortune Card Risk/Reward
- Higher potential rewards require higher risks
- Failed gambles should have meaningful consequences  
- Success should feel rewarding but not overwhelming
- Corruption as balancing factor for powerful effects

#### Card Synergies
- Cards within same class should have synergies
- Cross-class combinations should be viable
- Support multiple playstyles per class
- Encourage deck building decisions

This database structure supports the theme-agnostic core while providing rich content for the Australian Gold Rush setting. The Prospector's Fortune specialization creates a unique risk/reward gameplay style that differentiates from traditional card battlers.