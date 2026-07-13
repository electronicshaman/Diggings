extends Resource
class_name CurioEffect

const DEBUG_ENABLED: bool = true

# Base class for all curio effects
# Each effect is a modular resource that can be applied to curios

@export var description: String = "Base effect description"

# When this effect triggers
@export_enum("passive", "combat_start", "turn_start", "turn_end", "card_played", "damage_dealt", "damage_taken", "enemy_defeated", "rest", "shop_entered", "node_selected") var trigger_event: String = "passive"

# Additional trigger conditions
@export var only_first_per_combat: bool = false  # Only trigger once per combat
@export var only_first_per_turn: bool = false  # Only trigger once per turn
@export var chance_to_trigger: float = 1.0  # 0.0 to 1.0 probability

# Track if already triggered this combat/turn (managed by CurioManager)
var triggered_this_combat: bool = false
var triggered_this_turn: bool = false

# Virtual method to be overridden by specific effects
# game_state: Reference to the game systems for state changes
# curio_data: The curio that owns this effect
# context: Dictionary with contextual information (e.g., card_played, damage_amount, etc.)
func apply_effect(_game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
	GLog.warn("CurioEffect.apply_effect() called but not overridden!")
	GLog.warn("Effect: %s" % get_effect_name())

# Check if this effect can trigger given the current context
func can_trigger(_game_state: Node, _context: Dictionary) -> bool:
	# Check once-per-combat restriction
	if only_first_per_combat and triggered_this_combat:
		return false
	
	# Check once-per-turn restriction
	if only_first_per_turn and triggered_this_turn:
		return false
	
	# Check chance to trigger
	if chance_to_trigger < 1.0:
		var roll = randf()  # unreachable from curated run: CurioEffect.can_trigger() only runs for active_curios, which no curated-run code path populates
		if roll > chance_to_trigger:
			return false
	
	# Additional context-specific checks can be added in subclasses
	return true

# Reset combat-based tracking
func reset_combat_tracking() -> void:
	triggered_this_combat = false
	triggered_this_turn = false

# Reset turn-based tracking
func reset_turn_tracking() -> void:
	triggered_this_turn = false

# Mark as triggered
func mark_triggered() -> void:
	if only_first_per_combat:
		triggered_this_combat = true
	if only_first_per_turn:
		triggered_this_turn = true

# Get formatted description for UI
func get_formatted_description() -> String:
	var desc = description
	if chance_to_trigger < 1.0:
		desc = "(%d%% chance) %s" % [int(chance_to_trigger * 100), desc]
	return desc

# Helper to retrieve a display name for the effect; override if needed.
func get_effect_name() -> String:
	# Fallback to script filename or class name if subclass doesn't override
	var s = get_script()
	if s and s.has_method("get_path"):
		var p = s.get_path()
		if typeof(p) == TYPE_STRING and p != "":
			return p.get_file().get_basename()
	return get_class()

# Get required context keys for this effect
func get_required_context_keys() -> Array[String]:
	return []

# Validate that required context is present
func validate_context(context: Dictionary) -> bool:
	for key in get_required_context_keys():
		if not context.has(key):
			GLog.warn("CurioEffect '%s' missing required context key: %s" % [get_effect_name(), key])
			return false
	return true