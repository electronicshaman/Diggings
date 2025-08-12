extends Resource
class_name CardEffect

const DEBUG_ENABLED: bool = true

# Base class for all card effects
# Each effect is a modular resource that can be applied to cards

@export var effect_name: String = "Base Effect"
@export var description: String = "Base effect description"

# Virtual method to be overridden by specific effects
# duel_manager: Reference to the duel system for state changes
# card_data: The card that triggered this effect
# results: Dictionary containing effect results to modify
func apply_effect(_duel_manager: Node, _card_data: Resource, _results: Dictionary) -> void:
	GLog.warn("CardEffect.apply_effect() called but not overridden!")
	GLog.warn("Effect: %s" % effect_name)

# Helper method for effects that need to check conditions
func can_apply(_duel_manager: Node, _card_data: Resource) -> bool:
	return true

# Helper method for getting effect description for UI
# Method to return required keys for the effect
func get_required_keys() -> Array[String]:
	return []
func get_formatted_description() -> String:
	return description
