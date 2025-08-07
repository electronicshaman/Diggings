# Theme-Agnostic Core System TODO - Clean Architecture Implementation

> **Clean Slate Approach**: Build theme-agnostic core system with "The Rush" as primary theme

*Created: 2025-08-05 - Streamlined strategy for clean theme architecture*

## Philosophy

Build a **theme-agnostic core** that loads theme packages, with "The Rush" (Australian Gold Rush) as the primary and initial theme.

## Phase 1: Core Theme Framework Architecture

### 1.1 Theme Configuration System

**NEW FILES TO CREATE:**

```
themes/
├── theme_manager.gd                 # Core theme loading system
├── theme_config.gd                  # Theme configuration resource
├── card_type_definition.gd         # Card type resource definition
└── the_rush/
    ├── theme_config.tres           # Australian theme configuration  
    ├── characters/                 # Australian character classes
    ├── cards/                      # Australian cards organized by type
    │   ├── gold/                   # Mining/combat cards
    │   ├── grit/                   # Survival/defense cards  
    │   ├── grog/                   # Social/pub cards
    │   └── gamble/                 # Fortune/speculation cards
    ├── enemies/                    # Australian enemies
    └── curios/                     # Australian curios
```

### 1.2 Theme-Agnostic Core Resources

**MODIFY EXISTING CORE FILES:**

```
scripts/cards/CardData.gd           # Remove hardcoded enum, use dynamic types
scripts/cards/Card.gd               # Remove hardcoded colors/symbols  
scripts/characters/CharacterClass.gd # Theme-agnostic character system
scripts/globals/GameState.gd       # Add theme management
project.godot                       # Add ThemeManager as autoload
```

### 1.3 Theme Configuration Resource Structure

**CREATE: `scripts/themes/ThemeConfig.gd`**

```gdscript
extends Resource
class_name ThemeConfig

@export var theme_name: String = "The Rush"
@export var theme_description: String = "Australian Gold Rush adventure"
@export var setting_period: String = "1850s-1890s Australian Gold Fields"

# Card type definitions (themed flavor)
@export var card_types: Array[CardTypeDefinition] = []

# Card handling definitions (themed flavor for mechanics)
@export var card_handling_types: Array[CardHandlingDefinition] = []

# Asset paths (relative to theme directory)
@export var characters_path: String = "characters/"
@export var cards_path: String = "cards/"
@export var enemies_path: String = "enemies/"
@export var curios_path: String = "curios/"

# UI Theme
@export var ui_theme: Theme
@export var background_music: AudioStream
@export var ambient_sounds: Array[AudioStream]

# Game balance parameters per theme
@export var starting_energy: int = 3
@export var starting_hand_size: int = 5
@export var max_sanity: int = 100
```

**CREATE: `scripts/themes/CardTypeDefinition.gd`**

```gdscript
extends Resource
class_name CardTypeDefinition

@export var type_name: String = "Gold"
@export var type_color: Color = Color(0.831, 0.686, 0.216)  # Australian gold
@export var type_symbol: String = "⛏️"
@export var type_description: String = "Mining tools and physical confrontation"
@export var chain_mechanic: String = "Gold Rush"
@export var chain_description: String = "Each Gold card increases next Gold damage"

# Theme-agnostic mechanical category (independent of flavor)
@export_enum("Combat", "Defense", "Social", "Fortune") var mechanical_category: String = "Combat"

# Mechanical properties
@export var base_damage_bonus: int = 0
@export var base_defense_bonus: int = 0
@export var special_properties: Array[String] = []
```

**CREATE: `scripts/themes/CardHandlingDefinition.gd`**

```gdscript
extends Resource
class_name CardHandlingDefinition

@export var handling_name: String = "Standard"
@export var display_name: String = "Standard"  # Theme-specific display name
@export var description: String = "Normal card behavior"
@export var icon: String = ""  # Theme-specific icon

# Core mechanical behavior (theme-agnostic)
@export var discards_after_use: bool = true
@export var discards_end_of_turn: bool = true
@export var starts_in_hand: bool = false
@export var removed_after_use: bool = false
@export var triggers_on_draw: bool = false
```

## Phase 2: Theme Manager Implementation

### 2.1 Theme-Agnostic Design Considerations

**Card Type Categories (Mechanical Foundation):**

```
Combat   → Damage-dealing, direct confrontation
Defense  → Protection, damage reduction, cover
Social   → Manipulation, information, networking  
Fortune  → RNG effects, luck modification, speculation
```

**Theme Mapping Examples:**

```
WILD WEST THEME:
Combat="Lead" (🔫, gunmetal), Defense="Leather" (🛡️, brown)
Social="Liquor" (🥃, amber), Fortune="Luck" (🎲, green)

AUSTRALIAN THEME:  
Combat="Guns" (🔫, guns), Defense="Grit" (🛡️, brown)
Social="Grog" (🍺, amber), Fortune="Gamble" (🎲, green)

STEAMPUNK THEME (future):
Combat="Steel" (⚙️, metallic), Defense="Steam" (🛡️, blue)
Social="Gear" (🔧, copper), Fortune="Spark" (⚡, yellow)
```

**Card Handling Mapping (Mechanical → Thematic) Examples:**

```
CORE MECHANICS → WILD WEST → AUSTRALIAN → STEAMPUNK
Standard       → Normal    → Standard  → Regular
StartInHand    → Holstered → Swag      → Equipped  
TriggerOnDraw  → QuickDraw → Flash     → Automatic
NoDiscardTurn  → Hold      → Keep      → Maintain
OneShot        → OneShot   → Spent     → Consumed
```

## Phase 3: Create Australian Theme

### 3.1 Create Australian Theme Structure

**CREATE: `themes/the_rush/theme_config.tres`**

- Define Guns/Grit/Grog/Gamble as CardTypeDefinitions
- Set Australian UI theme and audio
- Configure game balance for Australian setting

**CREATE AUSTRALIAN CONTENT:**

```
themes/the_rush/
├── theme_config.tres              # Contains CardTypeDefinitions and CardHandlingDefinitions
├── characters/
│   ├── bushranger.tres            # Outlaw survival, bush warfare
│   ├── tracker.tres               # Aboriginal guide, survival expert  
│   ├── miner.tres                 # Underground specialist, explosives
│   ├── prospector.tres            # Gold seeker, claim finder
│   ├── doctor.tres                # Frontier medic, saw-bones
│   ├── publican.tres              # Pub owner, social networks
│   ├── priest.tres                # Missionary, moral authority
│   └── swagman.tres               # Wandering worker, jack-of-trades
├── cards/
│   ├── combat/                      
│   │   ├── pickaxe_strike.tres
│   │   ├── cave_in.tres
│   │   ├── gold_pan_smash.tres
│   │   └── tool_maintenance.tres
│   ├── defense/                      
│   │   ├── bush_tucker.tres
│   │   ├── weather_the_storm.tres
│   │   └── kangaroo_hide.tres
│   ├── social/                      
│   │   ├── bush_telegraph.tres
│   │   ├── rotgut_whiskey.tres
│   │   └── pub_brawl.tres
│   └── fortune/                    
│       ├── strike_gold.tres
│       ├── claim_jumping.tres
│       └── prospector_instinct.tres
├── enemies/
│   ├── mad_dog_morgan.tres        # Historical bushranger
│   ├── gentleman_bandit.tres      # Sophisticated criminal
│   ├── blasting_bill.tres         # Mining saboteur
│   ├── shanghai_sally.tres        # Criminal pub owner
│   ├── crocodile_jack.tres        # Outback survivor
│   └── the_mystic.tres            # Aboriginal shaman/cosmic horror
└── curios/
    ├── lucky_nugget.tres
    ├── bushman_compass.tres
    └── dreamtime_artifact.tres
```

**Australian Card Handling Definitions:**

```
Standard → "Standard" (normal behavior)
StartInHand → "Swag" (starts in hand like a swagman's pack)
TriggerOnDraw → "Flash" (like a flash of inspiration/gold)
NoDiscardTurn → "Keep" (keep for next turn)
OneShot → "Oneshot" (resource exhausted, like a mine)
```

## Phase 4: Template System for Future Themes

### 4.1 Content Templates

**CREATE: `templates/`**

```
templates/
├── character_template.tres         # Base character class structure
├── card_template.tres             # Base card structure  
├── enemy_template.tres            # Base enemy structure
├── curio_template.tres            # Base curio structure
├── theme_config_template.tres     # Theme configuration template
└── content_creation_guide.md      # How to create theme content
```

## Benefits of This Clean Approach

### 🎯 **Advantages:**

- **No legacy constraints** - Build modern, clean architecture
- **Focused development** - Single theme to perfect first
- **Future-ready** - Architecture supports unlimited themes  
- **Clean codebase** - No compatibility hacks or workarounds
- **Fast iteration** - No need to preserve old content

### 🔧 **Technical Benefits:**

- No enum migration issues
- Clean, consistent architecture
- Performance optimized from start
- Easy debugging and testing
- Modern Godot 4.4 patterns

### 🎨 **Creative Benefits:**  

- Australian theme gets full attention
- Authentic, researched content
- Perfect integration with Lovecraftian elements
- Template system enables community themes

## Success Criteria

- [ ] Core game functions with clean theme architecture
- [ ] Australian theme provides complete, polished experience
- [ ] Template system enables rapid future theme creation
- [ ] No performance degradation from theme system
- [ ] Development tools support efficient content creation
- [ ] Documentation enables theme creators

---

**This approach prioritizes clean architecture and focused content creation, setting up a robust foundation for The Rush and future themes.**

*"From the code mines of architecture to the gold fields of content - clean and focused development ahead..."*
