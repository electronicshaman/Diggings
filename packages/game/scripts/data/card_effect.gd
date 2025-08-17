extends Resource
class_name CardEffect

const DEBUG_ENABLED: bool = true

# Base class for all card effects
# Each effect is a modular resource that can be applied to cards

@export var description: String = "Base effect description"

# Required API: instance-aware effect application
func apply_effect_with_instance(_duel_manager: Node, _card_instance, _results: Dictionary) -> void:
	GLog.warn("CardEffect.apply_effect_with_instance() called but not overridden!")
	GLog.warn("Effect: %s" % get_effect_name())

# Helper method for effects that need to check conditions
func can_apply_with_instance(_duel_manager: Node, _card_instance) -> bool:
	return true

# Helper method for getting effect description for UI
# Method to return required keys for the effect
func get_required_keys() -> Array[String]:
	return []
func get_formatted_description() -> String:
	return description

# Helper to retrieve a display name for the effect; override if needed.
func get_effect_name() -> String:
	# Fallback to script filename or class name if subclass doesn't override
	var s = get_script()
	if s and s.has_method("get_path"):
		var p = s.get_path()
		if typeof(p) == TYPE_STRING and p != "":
			return p.get_file().get_basename()
	return get_class()
