# Design Document: DuelManager SRP Refactor

## Overview

This design refactors the monolithic 966-line DuelManager into a coordinator pattern with 5 focused components. Each component has a single responsibility, making the codebase more maintainable, testable, and extensible.

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      DuelManager                             │
│                   (Coordinator/Facade)                       │
│  - Instantiates components                                   │
│  - Routes public API calls                                   │
│  - Emits signals for external consumers                      │
└─────────────────────────────────────────────────────────────┘
         │           │           │           │           │
         ▼           ▼           ▼           ▼           ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ DuelFlow    │ │ EnemyAI     │ │ Card        │ │ ClassPassive│ │ TestSequence│
│ Controller  │ │ Controller  │ │ Resolver    │ │ Handler     │ │ Handler     │
├─────────────┤ ├─────────────┤ ├─────────────┤ ├─────────────┤ ├─────────────┤
│ Turn phases │ │ AI types    │ │ Validation  │ │ Preacher    │ │ Multi-battle│
│ Win/loss    │ │ Card select │ │ Cost payment│ │ passives    │ │ sequences   │
│ Transitions │ │ Energy mgmt │ │ Resolution  │ │ EventBus    │ │ State track │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
         │           │           │
         └───────────┴───────────┘
                     │
                     ▼
              ┌─────────────┐
              │ DuelState   │
              │ (Shared)    │
              └─────────────┘
```

## Architecture

### Dependency Injection Pattern

Components receive their dependencies through constructor injection, enabling:
- Easy unit testing with mock dependencies
- Clear dependency graph
- Loose coupling between components

```gdscript
# DuelManager creates and wires components
func _ready():
    flow_controller = DuelFlowController.new(duel_state)
    ai_controller = EnemyAIController.new(duel_state)
    card_resolver = CardResolver.new(duel_state, effect_processor)
    passive_handler = ClassPassiveHandler.new(duel_state)
    test_handler = TestSequenceHandler.new()
    
    # Wire inter-component communication
    flow_controller.card_resolver = card_resolver
    flow_controller.ai_controller = ai_controller
```

### Signal Flow

```
External Code → DuelManager → Component → DuelState
                    ↓
              Signal Emission
                    ↓
              UI/Other Systems
```

## Components and Interfaces

### 1. DuelFlowController

**File:** `scripts/combat/duel_flow_controller.gd`

**Responsibility:** Manages turn structure, phase transitions, and win/loss conditions.

```gdscript
class_name DuelFlowController
extends RefCounted

signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal duel_ended(winner: String)

var duel_state: DuelState
var card_resolver: CardResolver
var ai_controller: EnemyAIController

const ENEMY_TURN_START_DELAY: float = 1.0

func _init(state: DuelState) -> void
func start_duel(player_deck: DeckData, enemy_data: EnemyState) -> void
func start_player_turn() -> void
func end_player_turn() -> void
func start_enemy_turn() -> void
func end_enemy_turn() -> void
func check_win_loss_conditions() -> String  # Returns "player", "enemy", or ""
func is_duel_over() -> bool
```

### 2. EnemyAIController

**File:** `scripts/combat/enemy_ai_controller.gd`

**Responsibility:** Selects cards for enemy to play based on AI personality.

```gdscript
class_name EnemyAIController
extends RefCounted

var duel_state: DuelState

const MAX_CARDS_PER_TURN: int = 3

func _init(state: DuelState) -> void
func get_playable_cards(enemy: EnemyState) -> Array[CardData]
func select_card(enemy: EnemyState, playable: Array[CardData]) -> CardData
func execute_turn(enemy: EnemyState, card_resolver: CardResolver) -> void

# AI type implementations
func _select_aggressive(playable: Array[CardData]) -> CardData
func _select_defensive(playable: Array[CardData]) -> CardData
func _select_balanced(enemy: EnemyState, playable: Array[CardData]) -> CardData
func _select_cunning(enemy: EnemyState, playable: Array[CardData]) -> CardData
```

### 3. CardResolver

**File:** `scripts/combat/card_resolver.gd`

**Responsibility:** Validates, pays costs, and resolves card effects.

```gdscript
class_name CardResolver
extends RefCounted

signal card_played(card_instance: CardInstance)
signal enemy_card_played(card: CardData)

var duel_state: DuelState
var effect_processor: EffectProcessor

const CARD_STAGE_DELAY: float = 0.5
const ENEMY_CARD_PLAY_DELAY: float = 1.5

func _init(state: DuelState, processor: EffectProcessor) -> void
func can_play_card(card_data: CardData) -> bool
func play_player_card(card_instance: CardInstance) -> void
func play_enemy_card(enemy: EnemyState, card: CardData) -> void
func resolve_card(card_instance: CardInstance, is_player: bool) -> void
func apply_effect_results(results: Array[EffectResult], source, target) -> void

# Cost helpers
func _get_resource_costs(card_data: CardData) -> Dictionary
func _get_custom_resource_costs(card_data: CardData) -> Dictionary
func _pay_all_costs(player, card_instance: CardInstance) -> void
```

### 4. ClassPassiveHandler

**File:** `scripts/combat/class_passive_handler.gd`

**Responsibility:** Manages character class passive abilities.

```gdscript
class_name ClassPassiveHandler
extends RefCounted

var duel_state: DuelState
var _connected_signals: Array[Dictionary] = []

func _init(state: DuelState) -> void
func setup_passives() -> void
func cleanup() -> void

# Preacher passives
func _setup_preacher_passives() -> void
func _on_fervent_faith(player_data, resource_name: String, amount: int) -> void
func _on_temptation_check(player_data, resource_name: String, amount: int) -> void
func _on_holy_conviction(player_data: Object, context: Dictionary) -> void
func _trigger_temptation_choice() -> void

# Class detection
func _get_player_class() -> String
func _is_class(class_name: String) -> bool
```

### 5. TestSequenceHandler

**File:** `scripts/combat/test_sequence_handler.gd`

**Responsibility:** Manages test/debug multi-battle sequences.

```gdscript
class_name TestSequenceHandler
extends RefCounted

func is_test_duel() -> bool
func is_sequence_active() -> bool
func handle_duel_end(winner: String, duel_state: DuelState) -> Dictionary
func start_next_battle() -> DuelConfig
func get_persistent_state() -> Dictionary
func reset_sequence() -> void

# Returns: { "handled": bool, "scene_to_load": String, "should_emit_signals": bool }
```

### 6. DuelManager (Refactored)

**File:** `scripts/managers/duel_manager.gd`

**Responsibility:** Thin coordinator that wires components and routes API calls.

```gdscript
class_name DuelManager
extends Node

# Signals (maintained for backward compatibility)
signal duel_started
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal card_played(card)
signal duel_ended(winner: String)
signal enemy_card_played(card: CardData)

# Components
var flow_controller: DuelFlowController
var ai_controller: EnemyAIController
var card_resolver: CardResolver
var passive_handler: ClassPassiveHandler
var test_handler: TestSequenceHandler

# Shared state
var duel_state: DuelState
var effect_processor: EffectProcessor

func _ready() -> void  # Wire components
func start_new_duel(player_deck: DeckData, enemy_data: Resource) -> void
func play_card(card_instance: CardInstance) -> void
func can_play_card(card_data: CardData) -> bool
func end_player_turn() -> void

# Getters (delegate to duel_state)
func get_hand_cards() -> Array[CardInstance]
func get_deck_count() -> int
func get_discard_count() -> int
# ... etc
```

## Data Models

### Component Communication

Components communicate through:
1. **Shared DuelState** - All components read/write to the same state object
2. **Direct method calls** - Components call each other's methods when needed
3. **Signals** - For loose coupling with external systems (UI, etc.)

### State Ownership

| State | Owner | Readers |
|-------|-------|---------|
| DuelState | DuelManager | All components |
| Turn count | DuelFlowController | CardResolver |
| AI memory | EnemyAIController | - |
| Passive connections | ClassPassiveHandler | - |
| Sequence state | TestSequenceHandler | DuelFlowController |



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Turn Alternation

*For any* duel in progress, after a player turn ends, the next turn SHALL be an enemy turn, and after an enemy turn ends, the next turn SHALL be a player turn (unless the duel has ended).

**Validates: Requirements 1.2, 1.3**

### Property 2: Win/Loss Condition Accuracy

*For any* duel state, the win/loss check SHALL return:
- "player" if enemy health <= 0
- "enemy" if player health <= 0 OR player sanity <= 0
- "" (empty) if neither condition is met

**Validates: Requirements 1.4, 1.5**

### Property 3: AI Card Selection by Type

*For any* enemy with a given AI type and a set of playable cards:
- "aggressive" AI SHALL select Attack cards when available
- "defensive" AI SHALL select Skill cards or lowest-cost cards when available
- "balanced" AI SHALL select based on health ratios (defensive when low health, aggressive when player is low)
- "cunning" AI SHALL counter the most-played player card type

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

### Property 4: AI Energy Constraint

*For any* card selected by EnemyAIController, the card's energy cost SHALL be less than or equal to the enemy's current energy.

**Validates: Requirements 2.6**

### Property 5: AI Turn Card Limit

*For any* enemy turn, the number of cards played SHALL NOT exceed MAX_CARDS_PER_TURN (3).

**Validates: Requirements 2.7**

### Property 6: Class Passive Lifecycle

*For any* duel, after setup_passives() is called, the correct passives for the player's class SHALL be registered. After cleanup() is called, no passive signal handlers SHALL remain connected.

**Validates: Requirements 3.1, 3.6**

### Property 7: Preacher Passive Effects

*For any* Preacher player:
- Gaining Faith SHALL grant +1 defense (Fervent Faith)
- Reaching max Faith SHALL trigger Temptation choice
- Having Faith >= 5 SHALL add +10% to Fortune success chance (Holy Conviction)

**Validates: Requirements 3.2, 3.3, 3.4**

### Property 8: Test Sequence Isolation

*For any* duel where is_test_duel is false, the TestSequenceHandler SHALL NOT modify duel flow or state.

**Validates: Requirements 4.1, 4.6**

### Property 9: Test Sequence State Transitions

*For any* active test sequence:
- Victory SHALL advance current_enemy_index and persist health/energy
- Defeat SHALL reset the sequence and clear persistent state
- Completing all enemies SHALL mark sequence as complete

**Validates: Requirements 4.2, 4.3, 4.4**

### Property 10: Card Cost Validation and Payment

*For any* card and player state:
- can_play_card() SHALL return true IFF player has sufficient energy, sanity, and resources
- After play_player_card(), all costs SHALL be deducted from player state
- Actual energy cost SHALL equal base cost minus any active modifiers

**Validates: Requirements 5.1, 5.2, 5.3**

### Property 11: Effect Resolution and Routing

*For any* resolved card:
- Damage effects SHALL be applied to the target
- Defense/heal effects SHALL be applied to the source
- Card SHALL be moved to correct pile based on handling type (Standard→discard, Exhaust→removed, Hold→hand)

**Validates: Requirements 5.4, 5.5, 5.6, 5.7**

### Property 12: Backward Compatibility Signals

*For any* duel lifecycle, the DuelManager SHALL emit signals in the same order and with the same parameters as the original implementation:
- duel_started at duel start
- turn_started(true) at player turn start
- turn_ended(true) at player turn end
- card_played(card) when player plays a card
- enemy_card_played(card) when enemy plays a card
- duel_ended(winner) when duel concludes

**Validates: Requirements 7.2**

## Error Handling

### Component Initialization Errors

```gdscript
# DuelManager._ready()
if not duel_state:
    duel_state = DuelState.new()
    GLog.warn("Created default DuelState - no state was provided")

if not effect_processor:
    effect_processor = EffectProcessor.new()
    GLog.warn("Created default EffectProcessor")
```

### Null Safety in Components

Each component validates its dependencies:

```gdscript
# CardResolver.can_play_card()
func can_play_card(card_data: CardData) -> bool:
    if not card_data:
        GLog.error("can_play_card called with null card_data")
        return false
    if not duel_state or not duel_state.player_data:
        GLog.error("can_play_card called with invalid duel state")
        return false
    # ... validation logic
```

### AI Fallback Behavior

```gdscript
# EnemyAIController.select_card()
func select_card(enemy: EnemyState, playable: Array[CardData]) -> CardData:
    if playable.is_empty():
        return null
    
    match enemy.ai_type:
        "aggressive": return _select_aggressive(playable)
        "defensive": return _select_defensive(playable)
        "balanced": return _select_balanced(enemy, playable)
        "cunning": return _select_cunning(enemy, playable)
        _:
            GLog.warn("Unknown AI type '%s', using default" % enemy.ai_type)
            return playable[0]  # Fallback to first card
```

### Signal Connection Safety

```gdscript
# ClassPassiveHandler.setup_passives()
func _connect_safe(signal_name: String, callable: Callable) -> void:
    if EventBus.has_signal(signal_name):
        if not EventBus.is_connected(signal_name, callable):
            EventBus.connect(signal_name, callable)
            _connected_signals.append({"signal": signal_name, "callable": callable})
    else:
        GLog.warn("Signal '%s' not found on EventBus" % signal_name)
```

## Testing Strategy

### Unit Tests

Unit tests verify specific examples and edge cases for each component:

**DuelFlowController:**
- Turn starts with correct initial state
- Turn alternation works correctly
- Win condition detected when enemy health = 0
- Loss condition detected when player health = 0
- Loss condition detected when player sanity = 0

**EnemyAIController:**
- Aggressive AI selects Attack card when available
- Defensive AI selects Skill card when available
- AI respects energy constraints
- AI stops at MAX_CARDS_PER_TURN

**CardResolver:**
- can_play_card returns false when insufficient energy
- can_play_card returns false when insufficient sanity
- Cost modifiers applied correctly
- Card routed to correct pile after resolution

**ClassPassiveHandler:**
- Preacher passives registered on setup
- Non-Preacher classes don't get Preacher passives
- Cleanup disconnects all signals

**TestSequenceHandler:**
- Non-test duels not affected
- Victory advances sequence
- Defeat resets sequence

### Property-Based Tests

Property tests use GDScript's randomization to verify universal properties:

**Testing Framework:** GUT (Godot Unit Testing) with custom property test helpers

**Configuration:** Minimum 100 iterations per property test

```gdscript
# Example property test structure
func test_property_ai_energy_constraint():
    # Feature: duel-manager-srp-refactor, Property 4: AI Energy Constraint
    for i in range(100):
        var enemy = _generate_random_enemy_state()
        var playable = ai_controller.get_playable_cards(enemy)
        var selected = ai_controller.select_card(enemy, playable)
        
        if selected:
            assert_true(
                selected.energy_cost <= enemy.stats.current_energy,
                "AI selected card costing %d with only %d energy" % [
                    selected.energy_cost, enemy.stats.current_energy
                ]
            )
```

### Integration Tests

Integration tests verify components work together:

- Full duel flow from start to end
- Player card play through CardResolver
- Enemy turn through AI + CardResolver
- Preacher passives trigger during duel
- Test sequence completes multiple battles

### Test File Organization

```
scripts/debug/
├── test_duel_flow_controller.gd
├── test_enemy_ai_controller.gd
├── test_card_resolver.gd
├── test_class_passive_handler.gd
├── test_test_sequence_handler.gd
└── test_duel_manager_integration.gd
```
