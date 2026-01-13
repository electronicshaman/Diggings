# Narrative Graph System - Technical Specification

**Version:** 1.0
**Last Updated:** 2026-01-13
**Status:** Draft

---

## 1. Executive Summary

This document specifies the technical implementation of a **Graph Rewriting Narrative System** for a Godot 4.5 roguelite card battler. The system must support:

- **400+ narrative nodes** organized as Godot Resources
- **Dynamic graph manipulation** (node injection, removal, conditional availability)
- **Tag-based state tracking** for narrative consequences
- **SOLID principles** for maintainability and extensibility
- **Integration** with existing EventBus, ResourceManager, and Encounter systems

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTOLOAD LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│  NarrativeManager    │  EventBus         │  ResourceManager         │
│  (Graph State)       │  (Communication)  │  (Loading/Caching)       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        RESOURCE LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│  NarrativeNodeData   │  NarrativeChoice  │  NarrativeCondition     │
│  (The "What")        │  (The "Options")  │  (The "When")           │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        EFFECT LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│  NarrativeOutcome    │  GraphRewrite     │  HandlerBase (existing) │
│  (Results)           │  (Graph Ops)      │  (Game Effects)         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Design Principles

### 3.1 SOLID Compliance

| Principle | Application |
|-----------|-------------|
| **Single Responsibility** | Each Resource class has one job: `NarrativeNodeData` holds content, `NarrativeCondition` evaluates eligibility, `GraphRewrite` modifies graph state. |
| **Open/Closed** | New node types, conditions, and outcomes are added by creating new Resources, not modifying existing classes. |
| **Liskov Substitution** | All narrative resources extend a common `NarrativeResource` base; systems accept the base type. |
| **Interface Segregation** | Small, focused interfaces: `IConditional`, `IExecutable`, `ITagProvider`. |
| **Dependency Inversion** | High-level `NarrativeManager` depends on abstract `NarrativeResource`, not concrete implementations. |

### 3.2 Godot 4.5 Best Practices

- **Resources over Nodes**: All narrative data is `Resource`-based (serializable, inspector-editable, hot-reloadable).
- **Composition over Inheritance**: Effects and conditions are arrays of small, composable Resources.
- **Signal-based Communication**: All cross-system events via `EventBus`.
- **Export-driven Configuration**: All tunable values exposed via `@export`.
- **Defensive Nullability**: All references use null-coalescing and early returns.

---

## 4. Resource Specifications

### 4.1 NarrativeNodeData (Core)

```gdscript
## The atomic unit of narrative content.
## Each node represents a single scene, event, or decision point.
@tool
class_name NarrativeNodeData
extends Resource

# ═══════════════════════════════════════════════════════════════════════════
# IDENTITY
# ═══════════════════════════════════════════════════════════════════════════
@export var node_id: StringName = &""  ## Unique identifier (e.g., "the_drowned_claim")
@export var display_name: String = ""  ## Human-readable title for editor/debug
@export_multiline var hook_text: String = ""  ## The main narrative prose

# ═══════════════════════════════════════════════════════════════════════════
# CATEGORIZATION
# ═══════════════════════════════════════════════════════════════════════════
@export_enum("Choice", "Encounter", "StateCheck", "Rest", "Transition") var node_type: String = "Choice"
@export var biomes: Array[StringName] = []  ## Where this can appear (empty = anywhere)
@export_enum("Common", "Uncommon", "Rare", "Unique", "Story") var rarity: String = "Common"
@export var tags: Array[StringName] = []  ## Searchable metadata tags

# ═══════════════════════════════════════════════════════════════════════════
# ELIGIBILITY
# ═══════════════════════════════════════════════════════════════════════════
@export var prerequisites: Array[NarrativeCondition] = []  ## ALL must pass
@export var exclusions: Array[NarrativeCondition] = []  ## ANY blocks this node
@export var priority: int = 0  ## Higher = selected first when multiple eligible
@export var weight: float = 1.0  ## Random selection weight within priority tier
@export var max_occurrences: int = -1  ## -1 = unlimited, 0 = never, 1+ = limited

# ═══════════════════════════════════════════════════════════════════════════
# CHOICES
# ═══════════════════════════════════════════════════════════════════════════
@export var choices: Array[NarrativeChoice] = []

# ═══════════════════════════════════════════════════════════════════════════
# STATE CHECK (for StateCheck type nodes)
# ═══════════════════════════════════════════════════════════════════════════
@export var state_check_condition: NarrativeCondition  ## If set, auto-resolves
@export var state_check_true_node: StringName = &""  ## Redirect if true
@export var state_check_false_node: StringName = &""  ## Redirect if false

# ═══════════════════════════════════════════════════════════════════════════
# VARIANT HOOKS (Sanity/Corruption scaling)
# ═══════════════════════════════════════════════════════════════════════════
@export var hook_variants: Dictionary = {}  ## { "high_corruption": "Alt text...", "low_sanity": "..." }

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════════════════
func _validate_property(property: Dictionary) -> void:
	if property.name == "state_check_condition" and node_type != "StateCheck":
		property.usage = PROPERTY_USAGE_NO_EDITOR

func is_valid() -> bool:
	return node_id != &"" and (choices.size() > 0 or node_type == "StateCheck")

func get_hook_text(context: NarrativeContext) -> String:
	# Check for variant overrides based on context
	if context.corruption >= 7 and hook_variants.has("high_corruption"):
		return hook_variants["high_corruption"]
	if context.sanity <= 3 and hook_variants.has("low_sanity"):
		return hook_variants["low_sanity"]
	return hook_text
```

### 4.2 NarrativeChoice

```gdscript
## A single choice within a narrative node.
@tool
class_name NarrativeChoice
extends Resource

# ═══════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═══════════════════════════════════════════════════════════════════════════
@export var choice_text: String = ""  ## Button/option text
@export_multiline var outcome_text_success: String = ""  ## Shown on success
@export_multiline var outcome_text_failure: String = ""  ## Shown on failure (if skill check)

# ═══════════════════════════════════════════════════════════════════════════
# ELIGIBILITY
# ═══════════════════════════════════════════════════════════════════════════
@export var visibility_conditions: Array[NarrativeCondition] = []  ## Must pass to SHOW choice
@export var enabled_conditions: Array[NarrativeCondition] = []  ## Must pass to SELECT (greyed otherwise)

# ═══════════════════════════════════════════════════════════════════════════
# SKILL CHECK (optional)
# ═══════════════════════════════════════════════════════════════════════════
@export var has_skill_check: bool = false
@export_enum("Luck", "Strength", "Charisma", "Sanity", "Mechanics") var skill_check_type: String = "Luck"
@export_range(1, 10) var skill_check_dc: int = 5

# ═══════════════════════════════════════════════════════════════════════════
# OUTCOMES
# ═══════════════════════════════════════════════════════════════════════════
@export var outcomes_success: Array[NarrativeOutcome] = []
@export var outcomes_failure: Array[NarrativeOutcome] = []  ## Only used if has_skill_check

# ═══════════════════════════════════════════════════════════════════════════
# GRAPH REWRITES
# ═══════════════════════════════════════════════════════════════════════════
@export var graph_rewrites_success: Array[GraphRewrite] = []
@export var graph_rewrites_failure: Array[GraphRewrite] = []

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════
func is_visible(context: NarrativeContext) -> bool:
	for condition in visibility_conditions:
		if not condition.evaluate(context):
			return false
	return true

func is_enabled(context: NarrativeContext) -> bool:
	for condition in enabled_conditions:
		if not condition.evaluate(context):
			return false
	return true

func get_outcome_text(success: bool) -> String:
	return outcome_text_success if success else outcome_text_failure

func get_outcomes(success: bool) -> Array[NarrativeOutcome]:
	return outcomes_success if success else outcomes_failure

func get_graph_rewrites(success: bool) -> Array[GraphRewrite]:
	return graph_rewrites_success if success else graph_rewrites_failure
```

### 4.3 NarrativeCondition

```gdscript
## Evaluates a single condition against game state.
## Designed for composition - use multiple conditions for AND logic.
@tool
class_name NarrativeCondition
extends Resource

@export_enum(
	"HasTag",           ## Player has narrative tag
	"MissingTag",       ## Player does NOT have tag
	"TagValue",         ## Tag exists with specific value comparison
	"ResourceCheck",    ## Gold, Sanity, Health, Corruption threshold
	"ClassIs",          ## Player class matches
	"HasCurio",         ## Player has specific curio
	"ActRange",         ## Current act within range
	"BiomeIs",          ## Current biome matches
	"RandomChance",     ## Percentage chance (for variety)
	"NodeCompleted",    ## Specific node was completed this run
	"NodeNotCompleted", ## Specific node was NOT completed
	"Custom"            ## Calls a named function on NarrativeManager
) var condition_type: String = "HasTag"

@export var string_value: StringName = &""  ## Tag name, class name, curio ID, etc.
@export var int_value: int = 0  ## Threshold, act number, etc.
@export var int_value_max: int = 0  ## For range checks (ActRange uses int_value as min, int_value_max as max)
@export var float_value: float = 0.0  ## For RandomChance (0.0-1.0)
@export_enum("Equal", "NotEqual", "GreaterThan", "LessThan", "GreaterOrEqual", "LessOrEqual") var comparison: String = "GreaterOrEqual"

## Invert the result (NOT logic)
@export var invert: bool = false

## Human-readable description for editor
@export var description: String = ""

func evaluate(context: NarrativeContext) -> bool:
	var result := _evaluate_internal(context)
	return not result if invert else result

func _evaluate_internal(context: NarrativeContext) -> bool:
	match condition_type:
		"HasTag":
			return context.has_tag(string_value)
		"MissingTag":
			return not context.has_tag(string_value)
		"TagValue":
			return _compare(context.get_tag_value(string_value, 0), int_value)
		"ResourceCheck":
			return _compare(context.get_resource(string_value), int_value)
		"ClassIs":
			return context.player_class == string_value
		"HasCurio":
			return context.has_curio(string_value)
		"ActRange":
			var max_val = int_value_max if int_value_max > 0 else int_value
			return context.current_act >= int_value and context.current_act <= max_val
		"BiomeIs":
			return context.current_biome == string_value
		"RandomChance":
			return randf() < float_value
		"NodeCompleted":
			return context.is_node_completed(string_value)
		"NodeNotCompleted":
			return not context.is_node_completed(string_value)
		"Custom":
			return context.evaluate_custom(string_value)
	return false

func _compare(actual: Variant, expected: int) -> bool:
	var actual_int: int = actual if actual is int else 0
	match comparison:
		"Equal": return actual_int == expected
		"NotEqual": return actual_int != expected
		"GreaterThan": return actual_int > expected
		"LessThan": return actual_int < expected
		"GreaterOrEqual": return actual_int >= expected
		"LessOrEqual": return actual_int <= expected
	return false

func get_description() -> String:
	if description != "":
		return description
	# Auto-generate description
	match condition_type:
		"HasTag": return "Has tag '%s'" % string_value
		"MissingTag": return "Missing tag '%s'" % string_value
		"ResourceCheck": return "%s %s %d" % [string_value, comparison, int_value]
		"ClassIs": return "Class is %s" % string_value
		_: return "%s: %s" % [condition_type, string_value]
```

### 4.4 NarrativeOutcome

```gdscript
## A single effect that occurs when a choice is made.
## Wraps existing HandlerBase effects + narrative-specific effects.
@tool
class_name NarrativeOutcome
extends Resource

@export_enum(
	"ModifyResource",    ## Change Gold/Health/Sanity/Corruption
	"ApplyStatus",       ## Apply buff/debuff for next combat
	"AddCard",           ## Add card to deck
	"RemoveCard",        ## Remove card from deck
	"UpgradeCard",       ## Upgrade a card in deck
	"AddCurio",          ## Grant curio
	"RemoveCurio",       ## Take away curio
	"StartCombat",       ## Trigger combat encounter
	"ShowText",          ## Display additional narrative text
	"PlaySound",         ## Audio feedback
	"CustomHandler"      ## Delegate to existing HandlerBase
) var outcome_type: String = "ModifyResource"

@export var resource_type: StringName = &""  ## "gold", "health", "sanity", "corruption"
@export var int_value: int = 0  ## Amount to add/remove, status stacks, etc.
@export var string_value: String = ""  ## Card ID, curio ID, enemy ID, sound path, etc.
@export var handler_resource: Resource  ## For CustomHandler type

## Human-readable description for editor
@export var description: String = ""

func execute(context: NarrativeContext) -> void:
	match outcome_type:
		"ModifyResource":
			context.modify_resource(resource_type, int_value)
		"ApplyStatus":
			context.apply_status(string_value, int_value)
		"AddCard":
			context.add_card_to_deck(string_value)
		"RemoveCard":
			context.remove_card_from_deck(string_value)
		"UpgradeCard":
			context.upgrade_card(string_value)
		"AddCurio":
			context.add_curio(string_value)
		"RemoveCurio":
			context.remove_curio(string_value)
		"StartCombat":
			context.start_combat(string_value)
		"ShowText":
			context.show_text(string_value)
		"PlaySound":
			context.play_sound(string_value)
		"CustomHandler":
			if handler_resource and handler_resource.has_method("execute"):
				handler_resource.execute(context)

func get_description() -> String:
	if description != "":
		return description
	match outcome_type:
		"ModifyResource":
			var sign = "+" if int_value >= 0 else ""
			return "%s%d %s" % [sign, int_value, resource_type]
		"ApplyStatus":
			return "Apply %d %s" % [int_value, string_value]
		"AddCard":
			return "Add '%s' to deck" % string_value
		"StartCombat":
			return "Start combat: %s" % string_value
		_:
			return "%s: %s" % [outcome_type, string_value]
```

### 4.5 GraphRewrite

```gdscript
## Modifies the narrative graph structure.
## This is the "graph rewriting" core mechanic.
@tool
class_name GraphRewrite
extends Resource

@export_enum(
	"AddTag",           ## Add narrative tag to player state
	"RemoveTag",        ## Remove narrative tag
	"SetTagValue",      ## Set tag to specific value (not just bool)
	"IncrementTag",     ## Add to existing tag value (or set if missing)
	"InjectNode",       ## Add node to available pool
	"RemoveNode",       ## Remove node from available pool
	"UnlockLocation",   ## Make map location visitable
	"LockLocation",     ## Remove map location
	"SetNodePriority",  ## Change priority of existing node
	"QueueNode"         ## Force node to appear next (or within N encounters)
) var rewrite_type: String = "AddTag"

@export var target_id: StringName = &""  ## Tag name or Node ID
@export var int_value: int = 0  ## For SetTagValue, IncrementTag, or QueueNode timing
@export var string_value: String = ""  ## Additional context (e.g., source tracking)

## Optional: Only apply this rewrite if condition passes
@export var conditional: NarrativeCondition

## Human-readable description for editor
@export var description: String = ""

func execute(manager: NarrativeManager) -> void:
	if conditional and not conditional.evaluate(manager.get_context()):
		return
	
	match rewrite_type:
		"AddTag":
			manager.add_tag(target_id, true, string_value)
		"RemoveTag":
			manager.remove_tag(target_id)
		"SetTagValue":
			manager.add_tag(target_id, int_value, string_value)
		"IncrementTag":
			var current = manager.get_tag_value(target_id, 0)
			if current is int:
				manager.add_tag(target_id, current + int_value, string_value)
			else:
				manager.add_tag(target_id, int_value, string_value)
		"InjectNode":
			manager.inject_node(target_id)
		"RemoveNode":
			manager.remove_node_from_pool(target_id)
		"UnlockLocation":
			manager.unlock_location(target_id)
		"LockLocation":
			manager.lock_location(target_id)
		"SetNodePriority":
			manager.set_node_priority(target_id, int_value)
		"QueueNode":
			manager.queue_node(target_id, int_value)  # int_value = max encounters until forced

func get_description() -> String:
	if description != "":
		return description
	match rewrite_type:
		"AddTag": return "Add tag '%s'" % target_id
		"RemoveTag": return "Remove tag '%s'" % target_id
		"SetTagValue": return "Set '%s' = %d" % [target_id, int_value]
		"IncrementTag": return "Increment '%s' by %d" % [target_id, int_value]
		"InjectNode": return "Unlock node '%s'" % target_id
		"RemoveNode": return "Remove node '%s'" % target_id
		"QueueNode": return "Queue node '%s' (within %d)" % [target_id, int_value]
		_: return "%s: %s" % [rewrite_type, target_id]
```

---

## 5. NarrativeContext (Value Object)

```gdscript
## Immutable snapshot of game state for condition evaluation.
## Passed to conditions to avoid direct coupling to GameManager.
class_name NarrativeContext
extends RefCounted

var tags: Dictionary = {}
var completed_nodes: Dictionary = {}
var gold: int = 0
var health: int = 0
var max_health: int = 0
var sanity: int = 0
var max_sanity: int = 0
var corruption: int = 0
var current_act: int = 1
var current_day: int = 1
var player_class: StringName = &""
var current_biome: StringName = &""
var curios: Array[StringName] = []

# Custom evaluators registered by other systems
var _custom_evaluators: Dictionary = {}  # StringName -> Callable

# Reference to manager for outcome execution
var _manager: NarrativeManager

func has_tag(tag: StringName) -> bool:
	return tags.has(tag)

func get_tag_value(tag: StringName, default: Variant = null) -> Variant:
	return tags.get(tag, default)

func get_resource(resource_name: StringName) -> int:
	match resource_name:
		&"gold": return gold
		&"health": return health
		&"max_health": return max_health
		&"sanity": return sanity
		&"max_sanity": return max_sanity
		&"corruption": return corruption
		&"day": return current_day
		&"act": return current_act
	return 0

func has_curio(curio_id: StringName) -> bool:
	return curio_id in curios

func is_node_completed(node_id: StringName) -> bool:
	return completed_nodes.has(node_id)

func get_node_completion_count(node_id: StringName) -> int:
	return completed_nodes.get(node_id, 0)

func register_custom_evaluator(name: StringName, callable: Callable) -> void:
	_custom_evaluators[name] = callable

func evaluate_custom(name: StringName) -> bool:
	if _custom_evaluators.has(name):
		return _custom_evaluators[name].call(self)
	return false

# ═══════════════════════════════════════════════════════════════════════════
# OUTCOME EXECUTION (Delegates to EventBus)
# ═══════════════════════════════════════════════════════════════════════════
func modify_resource(resource: StringName, amount: int) -> void:
	EventBus.emit_game_event("modify_resource", [resource, amount])

func apply_status(status: String, stacks: int) -> void:
	EventBus.emit_game_event("apply_combat_status", [status, stacks])

func add_card_to_deck(card_id: String) -> void:
	EventBus.emit_game_event("add_card_to_deck", [card_id])

func remove_card_from_deck(card_id: String) -> void:
	EventBus.emit_game_event("remove_card_from_deck", [card_id])

func upgrade_card(card_id: String) -> void:
	EventBus.emit_game_event("upgrade_card", [card_id])

func add_curio(curio_id: String) -> void:
	EventBus.emit_game_event("add_curio", [curio_id])

func remove_curio(curio_id: String) -> void:
	EventBus.emit_game_event("remove_curio", [curio_id])

func start_combat(enemy_id: String) -> void:
	EventBus.emit_game_event("start_combat", [enemy_id])

func show_text(text: String) -> void:
	EventBus.emit_game_event("show_narrative_text", [text])

func play_sound(sound_id: String) -> void:
	EventBus.emit_game_event("play_sound", [sound_id])
```

---

## 6. NarrativeManager Autoload

```gdscript
## Central manager for the narrative graph system.
## Autoload singleton responsible for state, evaluation, and graph manipulation.
class_name NarrativeManager
extends Node

const DEBUG_ENABLED := true
const NODE_PATH := "res://data/narrative/nodes/"
const CACHE_SIZE := 50

# ═══════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════
signal tag_added(tag: StringName, value: Variant, source: String)
signal tag_removed(tag: StringName)
signal node_injected(node_id: StringName)
signal node_removed(node_id: StringName)
signal node_completed(node_id: StringName, completion_count: int)
signal node_queued(node_id: StringName, urgency: int)
signal node_presented(node: NarrativeNodeData)
signal choice_made(node_id: StringName, choice_index: int, success: bool)

# ═══════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════
## All narrative tags for the current run
var _tags: Dictionary = {}  # StringName -> { value: Variant, source: String, timestamp: int }

## Nodes completed this run (for max_occurrences tracking)
var _completed_nodes: Dictionary = {}  # StringName -> int (count)

## Dynamic pool of available nodes (base + injected - removed)
var _available_pool: Dictionary = {}  # StringName -> NarrativeNodeData

## Nodes forced to appear soon
var _queued_nodes: Array[Dictionary] = []  # [{node_id, encounters_remaining}]

## All loaded node metadata (lightweight)
var _node_registry: Dictionary = {}  # StringName -> { path: String, biomes: Array, rarity: String, prerequisites_empty: bool }

## Fully loaded node cache (LRU)
var _node_cache: Dictionary = {}  # StringName -> NarrativeNodeData
var _cache_order: Array[StringName] = []

## Current context (rebuilt each evaluation)
var _context: NarrativeContext

## History for debugging
var _rewrite_history: Array[Dictionary] = []  # [{type, target, value, timestamp}]
const MAX_HISTORY := 100

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_scan_and_register_nodes()
	EventBus.connect_safe(&"run_started", _on_run_started)
	EventBus.connect_safe(&"encounter_completed", _on_encounter_completed)

func _scan_and_register_nodes() -> void:
	var paths := _scan_directory(NODE_PATH)
	for path in paths:
		var node_data: NarrativeNodeData = load(path)
		if node_data and node_data.is_valid():
			_node_registry[node_data.node_id] = {
				"path": path,
				"biomes": node_data.biomes,
				"rarity": node_data.rarity,
				"prerequisites_empty": node_data.prerequisites.is_empty(),
				"priority": node_data.priority,
				"weight": node_data.weight
			}
	if DEBUG_ENABLED:
		GLog.info("NarrativeManager", "Registered %d narrative nodes" % _node_registry.size())

func _scan_directory(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(path)
	if not dir:
		if DEBUG_ENABLED:
			GLog.warn("NarrativeManager", "Could not open directory: %s" % path)
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := path.path_join(file_name)
		if dir.current_is_dir() and not file_name.begins_with("."):
			results.append_array(_scan_directory(full_path))
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			results.append(full_path)
		file_name = dir.get_next()
	return results

# ═══════════════════════════════════════════════════════════════════════════
# NODE LOADING (Lazy + Cached)
# ═══════════════════════════════════════════════════════════════════════════
func _get_node(node_id: StringName) -> NarrativeNodeData:
	# Check cache first
	if _node_cache.has(node_id):
		# Move to end of LRU order
		_cache_order.erase(node_id)
		_cache_order.append(node_id)
		return _node_cache[node_id]
	
	# Load from disk
	if not _node_registry.has(node_id):
		if DEBUG_ENABLED:
			GLog.warn("NarrativeManager", "Unknown node ID: %s" % node_id)
		return null
	
	var path: String = _node_registry[node_id].path
	var node_data: NarrativeNodeData = load(path)
	if not node_data:
		if DEBUG_ENABLED:
			GLog.error("NarrativeManager", "Failed to load node: %s from %s" % [node_id, path])
		return null
	
	# Add to cache
	_node_cache[node_id] = node_data
	_cache_order.append(node_id)
	
	# Evict oldest if over limit
	while _cache_order.size() > CACHE_SIZE:
		var oldest = _cache_order.pop_front()
		_node_cache.erase(oldest)
	
	return node_data

# ═══════════════════════════════════════════════════════════════════════════
# RUN MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════
func _on_run_started() -> void:
	reset_state()

func reset_state() -> void:
	_tags.clear()
	_completed_nodes.clear()
	_queued_nodes.clear()
	_rewrite_history.clear()
	_rebuild_available_pool()
	if DEBUG_ENABLED:
		GLog.info("NarrativeManager", "State reset. Available pool: %d nodes" % _available_pool.size())

func _rebuild_available_pool() -> void:
	_available_pool.clear()
	for node_id in _node_registry:
		var meta: Dictionary = _node_registry[node_id]
		# Add nodes with no prerequisites
		if meta.prerequisites_empty:
			_available_pool[node_id] = meta

# ═══════════════════════════════════════════════════════════════════════════
# TAG MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════
func add_tag(tag: StringName, value: Variant = true, source: String = "") -> void:
	var old_entry = _tags.get(tag)
	var old_value = old_entry.value if old_entry else null
	
	_tags[tag] = {
		"value": value,
		"source": source,
		"timestamp": Time.get_ticks_msec()
	}
	
	if old_value != value:
		tag_added.emit(tag, value, source)
		EventBus.emit_game_event("narrative_tag_added", [tag, value, source])
		_record_history("AddTag", tag, value)
		
		# Check if this unlocks new nodes
		_check_for_newly_eligible_nodes()

func remove_tag(tag: StringName) -> void:
	if _tags.erase(tag):
		tag_removed.emit(tag)
		EventBus.emit_game_event("narrative_tag_removed", [tag])
		_record_history("RemoveTag", tag, null)

func has_tag(tag: StringName) -> bool:
	return _tags.has(tag)

func get_tag_value(tag: StringName, default: Variant = null) -> Variant:
	if _tags.has(tag):
		return _tags[tag].value
	return default

func get_all_tags() -> Dictionary:
	var result := {}
	for tag in _tags:
		result[tag] = _tags[tag].value
	return result

# ═══════════════════════════════════════════════════════════════════════════
# GRAPH MANIPULATION
# ═══════════════════════════════════════════════════════════════════════════
func inject_node(node_id: StringName) -> void:
	if not _node_registry.has(node_id):
		if DEBUG_ENABLED:
			GLog.warn("NarrativeManager", "Cannot inject unknown node: %s" % node_id)
		return
	
	if not _available_pool.has(node_id):
		_available_pool[node_id] = _node_registry[node_id]
		node_injected.emit(node_id)
		_record_history("InjectNode", node_id, true)
		if DEBUG_ENABLED:
			GLog.info("NarrativeManager", "Injected node: %s" % node_id)

func remove_node_from_pool(node_id: StringName) -> void:
	if _available_pool.erase(node_id):
		node_removed.emit(node_id)
		_record_history("RemoveNode", node_id, false)
		if DEBUG_ENABLED:
			GLog.info("NarrativeManager", "Removed node from pool: %s" % node_id)

func queue_node(node_id: StringName, max_encounters: int = 3) -> void:
	if not _node_registry.has(node_id):
		if DEBUG_ENABLED:
			GLog.warn("NarrativeManager", "Cannot queue unknown node: %s" % node_id)
		return
	
	# Check if already queued
	for queued in _queued_nodes:
		if queued.node_id == node_id:
			queued.encounters_remaining = mini(queued.encounters_remaining, max_encounters)
			return
	
	_queued_nodes.append({
		"node_id": node_id,
		"encounters_remaining": max_encounters
	})
	node_queued.emit(node_id, max_encounters)
	_record_history("QueueNode", node_id, max_encounters)
	if DEBUG_ENABLED:
		GLog.info("NarrativeManager", "Queued node: %s (within %d encounters)" % [node_id, max_encounters])

func set_node_priority(node_id: StringName, priority: int) -> void:
	if _available_pool.has(node_id):
		_available_pool[node_id].priority = priority
	if _node_registry.has(node_id):
		_node_registry[node_id].priority = priority

# ═══════════════════════════════════════════════════════════════════════════
# NODE SELECTION
# ═══════════════════════════════════════════════════════════════════════════
func get_eligible_nodes(biome: StringName = &"", count: int = 1) -> Array[NarrativeNodeData]:
	_context = _build_context()
	
	# First, check queued nodes
	var forced := _pop_forced_node()
	if forced:
		return [forced]
	
	# Filter available pool by eligibility
	var candidates: Array[Dictionary] = []
	for node_id in _available_pool:
		var meta: Dictionary = _available_pool[node_id]
		if _is_node_eligible_quick(node_id, meta, biome):
			candidates.append({"id": node_id, "meta": meta})
	
	if candidates.is_empty():
		return []
	
	# Sort by priority (descending), then weighted random within tiers
	candidates.sort_custom(func(a, b): return a.meta.priority > b.meta.priority)
	
	# Select from top priority tier with weighted random
	var top_priority: int = candidates[0].meta.priority
	var top_tier: Array[Dictionary] = candidates.filter(func(c): return c.meta.priority == top_priority)
	
	var selected: Array[NarrativeNodeData] = []
	for i in range(mini(count, top_tier.size())):
		var chosen := _weighted_select(top_tier)
		if chosen:
			var node := _get_node(chosen.id)
			if node and _is_node_eligible_full(node):
				selected.append(node)
				top_tier.erase(chosen)
	
	return selected

func _weighted_select(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.is_empty():
		return {}
	
	var total_weight := 0.0
	for c in candidates:
		total_weight += c.meta.get("weight", 1.0)
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	for c in candidates:
		cumulative += c.meta.get("weight", 1.0)
		if roll <= cumulative:
			return c
	
	return candidates[-1]

func _pop_forced_node() -> NarrativeNodeData:
	for i in range(_queued_nodes.size() - 1, -1, -1):
		var queued = _queued_nodes[i]
		queued.encounters_remaining -= 1
		if queued.encounters_remaining <= 0:
			var node_id: StringName = queued.node_id
			_queued_nodes.remove_at(i)
			var node := _get_node(node_id)
			if node and _is_node_eligible_full(node):
				return node
	return null

func _is_node_eligible_quick(node_id: StringName, meta: Dictionary, biome: StringName) -> bool:
	# Quick checks using metadata only (no full load)
	
	# Check biome restriction
	var node_biomes: Array = meta.get("biomes", [])
	if not node_biomes.is_empty() and biome != &"" and biome not in node_biomes:
		return false
	
	# Check max occurrences (need to know count)
	# This requires the full node, so we defer to full check
	
	return true

func _is_node_eligible_full(node: NarrativeNodeData) -> bool:
	# Full eligibility check (requires loaded node)
	
	# Check max occurrences
	if node.max_occurrences >= 0:
		var count = _completed_nodes.get(node.node_id, 0)
		if count >= node.max_occurrences:
			return false
	
	# Check prerequisites (ALL must pass)
	for condition in node.prerequisites:
		if not condition.evaluate(_context):
			return false
	
	# Check exclusions (ANY blocks)
	for condition in node.exclusions:
		if condition.evaluate(_context):
			return false
	
	return true

# ═══════════════════════════════════════════════════════════════════════════
# CONTEXT BUILDING
# ═══════════════════════════════════════════════════════════════════════════
func _build_context() -> NarrativeContext:
	var ctx := NarrativeContext.new()
	ctx._manager = self
	ctx.tags = get_all_tags()
	ctx.completed_nodes = _completed_nodes.duplicate()
	
	# Pull from GameManager
	if GameManager:
		ctx.gold = GameManager.get_gold() if GameManager.has_method("get_gold") else 0
		ctx.health = GameManager.get_player_health() if GameManager.has_method("get_player_health") else 0
		ctx.max_health = GameManager.get_player_max_health() if GameManager.has_method("get_player_max_health") else 0
		ctx.sanity = GameManager.get_player_sanity() if GameManager.has_method("get_player_sanity") else 0
		ctx.max_sanity = GameManager.get_player_max_sanity() if GameManager.has_method("get_player_max_sanity") else 0
		ctx.corruption = GameManager.get_corruption() if GameManager.has_method("get_corruption") else 0
		ctx.current_act = GameManager.get_current_act() if GameManager.has_method("get_current_act") else 1
		ctx.current_day = GameManager.get_current_day() if GameManager.has_method("get_current_day") else 1
		ctx.player_class = GameManager.get_player_class() if GameManager.has_method("get_player_class") else &""
		ctx.current_biome = GameManager.get_current_biome() if GameManager.has_method("get_current_biome") else &""
		ctx.curios = GameManager.get_curio_ids() if GameManager.has_method("get_curio_ids") else []
	
	return ctx

func get_context() -> NarrativeContext:
	if not _context:
		_context = _build_context()
	return _context

func refresh_context() -> void:
	_context = _build_context()

# ═══════════════════════════════════════════════════════════════════════════
# CHOICE EXECUTION
# ═══════════════════════════════════════════════════════════════════════════
func execute_choice(node: NarrativeNodeData, choice_index: int) -> Dictionary:
	if choice_index < 0 or choice_index >= node.choices.size():
		if DEBUG_ENABLED:
			GLog.error("NarrativeManager", "Invalid choice index: %d for node %s" % [choice_index, node.node_id])
		return {"success": false, "outcome_text": ""}
	
	var choice: NarrativeChoice = node.choices[choice_index]
	var success := true
	
	# Handle skill check if present
	if choice.has_skill_check:
		success = _perform_skill_check(choice.skill_check_type, choice.skill_check_dc)
	
	# Get outcomes and rewrites based on success
	var outcomes := choice.get_outcomes(success)
	var rewrites := choice.get_graph_rewrites(success)
	var outcome_text := choice.get_outcome_text(success)
	
	# Execute outcomes
	_context = _build_context()
	for outcome in outcomes:
		outcome.execute(_context)
	
	# Execute graph rewrites
	for rewrite in rewrites:
		rewrite.execute(self)
	
	# Mark node completed
	mark_node_completed(node.node_id)
	
	# Emit signal
	choice_made.emit(node.node_id, choice_index, success)
	
	return {
		"success": success,
		"outcome_text": outcome_text,
		"outcomes": outcomes,
		"rewrites": rewrites
	}

func _perform_skill_check(skill_type: String, dc: int) -> bool:
	# Simple implementation - can be expanded
	var roll := randi_range(1, 10)
	var bonus := 0
	
	# Get bonus from player stats/curios/etc via EventBus
	# For now, just use the roll
	
	var success := (roll + bonus) >= dc
	if DEBUG_ENABLED:
		GLog.info("NarrativeManager", "Skill check (%s DC %d): rolled %d + %d = %s" % [
			skill_type, dc, roll, bonus, "SUCCESS" if success else "FAILURE"
		])
	return success

# ═══════════════════════════════════════════════════════════════════════════
# COMPLETION HANDLING
# ═══════════════════════════════════════════════════════════════════════════
func mark_node_completed(node_id: StringName) -> void:
	var count: int = _completed_nodes.get(node_id, 0) + 1
	_completed_nodes[node_id] = count
	node_completed.emit(node_id, count)
	_record_history("NodeCompleted", node_id, count)
	
	# Check if this unlocks any new nodes
	_check_for_newly_eligible_nodes()

func _check_for_newly_eligible_nodes() -> void:
	_context = _build_context()
	for node_id in _node_registry:
		if _available_pool.has(node_id):
			continue
		# Only check nodes with prerequisites (others are already in pool)
		var meta: Dictionary = _node_registry[node_id]
		if meta.prerequisites_empty:
			continue
		# Need full load to check prerequisites
		var node := _get_node(node_id)
		if node and _is_node_eligible_full(node):
			inject_node(node_id)

func _on_encounter_completed(encounter: Resource) -> void:
	if encounter and encounter.has_method("get_node_id"):
		mark_node_completed(encounter.get_node_id())

# ═══════════════════════════════════════════════════════════════════════════
# LOCATION MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════
func unlock_location(location_id: StringName) -> void:
	add_tag(&"location_unlocked_%s" % location_id, true, "unlock_location")
	EventBus.emit_game_event("location_unlocked", [location_id])

func lock_location(location_id: StringName) -> void:
	remove_tag(&"location_unlocked_%s" % location_id)
	EventBus.emit_game_event("location_locked", [location_id])

func is_location_unlocked(location_id: StringName) -> bool:
	return has_tag(&"location_unlocked_%s" % location_id)

# ═══════════════════════════════════════════════════════════════════════════
# HISTORY & DEBUG
# ═══════════════════════════════════════════════════════════════════════════
func _record_history(type: String, target: StringName, value: Variant) -> void:
	_rewrite_history.append({
		"type": type,
		"target": target,
		"value": value,
		"timestamp": Time.get_ticks_msec()
	})
	while _rewrite_history.size() > MAX_HISTORY:
		_rewrite_history.pop_front()

func get_history() -> Array[Dictionary]:
	return _rewrite_history.duplicate()

func get_debug_info() -> Dictionary:
	return {
		"tags": get_all_tags(),
		"completed_nodes": _completed_nodes.duplicate(),
		"available_pool_size": _available_pool.size(),
		"queued_nodes": _queued_nodes.duplicate(),
		"cache_size": _node_cache.size(),
		"registry_size": _node_registry.size()
	}

# ═══════════════════════════════════════════════════════════════════════════
# SAVE/LOAD
# ═══════════════════════════════════════════════════════════════════════════
func get_save_data() -> Dictionary:
	var tags_simplified := {}
	for tag in _tags:
		tags_simplified[tag] = _tags[tag].value
	
	return {
		"version": 1,
		"tags": tags_simplified,
		"completed_nodes": _completed_nodes.duplicate(),
		"queued_nodes": _queued_nodes.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	var version: int = data.get("version", 1)
	
	_tags.clear()
	var saved_tags: Dictionary = data.get("tags", {})
	for tag in saved_tags:
		_tags[tag] = {
			"value": saved_tags[tag],
			"source": "save_load",
			"timestamp": Time.get_ticks_msec()
		}
	
	_completed_nodes = data.get("completed_nodes", {})
	_queued_nodes = data.get("queued_nodes", [])
	
	_rebuild_available_pool()
	_check_for_newly_eligible_nodes()
	
	if DEBUG_ENABLED:
		GLog.info("NarrativeManager", "Loaded save data. Tags: %d, Completed: %d, Available: %d" % [
			_tags.size(), _completed_nodes.size(), _available_pool.size()
		])
```

---

## 7. Folder Structure

```
data/
└── narrative/
    ├── nodes/
    │   ├── goldfields/           # Biome-specific nodes
    │   │   ├── common/
    │   │   │   ├── the_drowned_claim.tres
    │   │   │   ├── the_stagnant_creek.tres
    │   │   │   └── ...
    │   │   ├── uncommon/
    │   │   ├── rare/
    │   │   │   └── the_singing_crystal.tres
    │   │   └── story/
    │   │       └── harrigans_revenge.tres
    │   ├── town/
    │   │   ├── common/
    │   │   │   ├── the_publican_offer.tres
    │   │   │   └── the_chinese_camp.tres
    │   │   ├── uncommon/
    │   │   └── rare/
    │   │       └── the_midnight_auction.tres
    │   ├── deep_mine/
    │   │   ├── common/
    │   │   │   ├── the_collapsed_tunnel.tres
    │   │   │   └── the_singing_shaft.tres
    │   │   └── ...
    │   ├── scrub/
    │   │   └── ...
    │   ├── road/
    │   │   └── ...
    │   └── universal/            # Nodes that can appear anywhere
    │       ├── the_dying_digger.tres
    │       └── the_preachers_warning.tres
    │
    ├── conditions/               # Reusable condition presets
    │   ├── high_corruption.tres  # corruption >= 7
    │   ├── low_sanity.tres       # sanity <= 3
    │   ├── is_tracker.tres       # class == tracker
    │   ├── is_preacher.tres
    │   ├── has_ancient_knowledge.tres
    │   └── ...
    │
    └── outcomes/                 # Reusable outcome presets
        ├── minor_health_loss.tres    # -5 health
        ├── major_sanity_loss.tres    # -10 sanity
        ├── gain_corruption.tres      # +1 corruption
        └── ...

scripts/
├── narrative/
│   ├── narrative_node_data.gd
│   ├── narrative_choice.gd
│   ├── narrative_condition.gd
│   ├── narrative_outcome.gd
│   ├── graph_rewrite.gd
│   └── narrative_context.gd
│
└── autoloads/
    └── narrative_manager.gd
```

---

## 8. Performance Considerations

### 8.1 Node Loading Strategy

| Phase | Strategy |
|-------|----------|
| **Startup** | Scan directories, load metadata only (node_id, biomes, rarity, prerequisites_empty, priority, weight). |
| **On Demand** | Full resource load when node is selected for presentation. |
| **LRU Cache** | Keep 50 most recently used full nodes in memory. |
| **Preloading** | When entering a biome, preload that biome's common nodes in background. |

### 8.2 Condition Evaluation

- **Early Exit**: Conditions are evaluated in order; first failure stops evaluation.
- **Context Caching**: `NarrativeContext` is rebuilt once per selection pass, not per node.
- **Metadata First**: Quick eligibility checks use registry metadata before loading full node.
- **Simple First**: Order conditions from cheapest to most expensive (HasTag < ResourceCheck < Custom).

### 8.3 Pool Management

- **Lazy Injection**: Nodes with prerequisites aren't in the pool until conditions are met.
- **Background Check**: `_check_for_newly_eligible_nodes()` runs after each node completion and tag change.
- **Batch Operations**: Multiple graph rewrites from a single choice are collected and applied together.

### 8.4 Memory Budget

| Component | Estimated Size | Count | Total |
|-----------|---------------|-------|-------|
| Registry entry | ~200 bytes | 400 | ~80 KB |
| Cached full node | ~2 KB | 50 | ~100 KB |
| Tags | ~100 bytes | ~50 per run | ~5 KB |
| **Total** | | | **~200 KB** |

---

## 9. EventBus Integration

Add the following signals to `scripts/autoloads/event_bus.gd`:

```gdscript
# ═══════════════════════════════════════════════════════════════════════════
# NARRATIVE SYSTEM SIGNALS
# ═══════════════════════════════════════════════════════════════════════════
signal narrative_tag_added(tag: StringName, value: Variant, source: String)
signal narrative_tag_removed(tag: StringName)
signal narrative_node_injected(node_id: StringName)
signal narrative_node_removed(node_id: StringName)
signal narrative_node_completed(node_id: StringName, count: int)
signal narrative_node_presented(node: Resource)
signal narrative_choice_made(node_id: StringName, choice_index: int, success: bool)
signal narrative_location_unlocked(location_id: StringName)
signal narrative_location_locked(location_id: StringName)

# For outcome execution
signal modify_resource(resource: StringName, amount: int)
signal apply_combat_status(status: String, stacks: int)
signal add_card_to_deck(card_id: String)
signal remove_card_from_deck(card_id: String)
signal upgrade_card(card_id: String)
signal show_narrative_text(text: String)
```

---

## 10. Integration Checklist

| System | Integration Point | Status |
|--------|-------------------|--------|
| **EventBus** | Add narrative signals (Section 9) | TODO |
| **GameManager** | Expose getters: `get_player_class()`, `get_current_biome()`, etc. | TODO |
| **SaveSystem** | Call `NarrativeManager.get_save_data()` / `load_save_data()` | TODO |
| **ResourceManager** | Add `"narrative"` to `RESOURCE_PATHS` | TODO |
| **project.godot** | Add `NarrativeManager` to autoloads after `CurioManager` | TODO |
| **UI** | Create `NarrativeNodeUI` scene for displaying nodes and choices | TODO |
| **Map System** | Query `NarrativeManager.get_eligible_nodes(biome)` when generating encounters | TODO |

---

## 11. Migration Path

### Phase 1: Foundation (Week 1)
1. Create script files for all Resource classes under `scripts/narrative/`
2. Add `NarrativeManager` to autoloads in `project.godot`
3. Add EventBus signals for narrative system
4. Create folder structure under `data/narrative/`
5. Create reusable condition/outcome presets

### Phase 2: Content Pipeline (Week 2)
1. Convert 10 example nodes from markdown to `.tres` resources
2. Create editor validation script to check node integrity
3. Test node selection and eligibility in isolation

### Phase 3: Integration (Week 3)
1. Hook `NarrativeManager` into existing encounter/map system
2. Create basic UI for node presentation
3. Wire up save/load with `SaveSystem`
4. Add debug overlay for tag/pool inspection

### Phase 4: Scale (Week 4+)
1. Build custom editor plugin for node creation
2. Mass-convert narrative content
3. Performance profiling with 400+ nodes
4. Graph visualization for debugging

---

## 12. Editor Tooling (Future)

### 12.1 Node Editor Plugin

A custom `@tool` editor for creating narrative nodes with:
- Live preview of hook text with variant switching
- Visual condition builder (dropdown + value fields)
- Outcome chain visualizer
- Graph rewrite impact preview
- Markdown import from example files

### 12.2 Graph Visualizer

A debug tool showing:
- All nodes in pool (colored by eligibility)
- Tag state as pill badges
- Queued nodes with countdown
- Recently completed nodes
- Connections (which nodes inject which)

### 12.3 Validation Tools

- **Orphan Detection**: Nodes that can never be reached (impossible prerequisites)
- **Deadlock Detection**: Tag requirements that form impossible cycles
- **Coverage Report**: Which biomes/rarities have how many nodes
- **Balance Check**: Average outcomes per choice (gold/health delta)

---

## 13. Open Questions & Decisions

| Question | Recommendation | Decision |
|----------|----------------|----------|
| Migrate `EncounterData` to `NarrativeNodeData`? | Keep both. Encounters = combat-focused, Narrative = story-focused. | TBD |
| Hook variants: separate nodes or inline? | Inline for minor text changes (`hook_variants`); separate nodes for fundamentally different encounters. | TBD |
| Weighted random within priority tiers? | Yes, added `weight: float = 1.0` to `NarrativeNodeData`. | Included |
| Undo/history for debugging? | Yes, store last 100 operations in `_rewrite_history`. | Included |
| Maximum tags per run? | Soft limit of ~200 tags; warn in debug if exceeded. | TBD |

---

## 14. Appendix: Example Resource Files

### 14.1 Condition Preset: `high_corruption.tres`

```ini
[gd_resource type="Resource" script_class="NarrativeCondition" ...]

[resource]
script = ExtResource("res://scripts/narrative/narrative_condition.gd")
condition_type = "ResourceCheck"
string_value = &"corruption"
int_value = 7
comparison = "GreaterOrEqual"
description = "Player has high corruption (7+)"
```

### 14.2 Outcome Preset: `minor_sanity_loss.tres`

```ini
[gd_resource type="Resource" script_class="NarrativeOutcome" ...]

[resource]
script = ExtResource("res://scripts/narrative/narrative_outcome.gd")
outcome_type = "ModifyResource"
resource_type = &"sanity"
int_value = -5
description = "Lose 5 Sanity"
```

---

## 15. Related Documents

- [Australian Gothic Style Bible](../fighting%20fantasy%20inspiration/Fighting%20Fantasy%20Style%20Bible.md)
- [Narrative Node Types](../NARRATIVE_NODE_TYPES.md)
- [Status Effects Specification](../STATUS_EFFECTS_SPEC.md)
- [Example Nodes](../examples/nodes/)
- [Event Bus Reference](../architecture/EVENT_BUS_REFERENCE.md)
