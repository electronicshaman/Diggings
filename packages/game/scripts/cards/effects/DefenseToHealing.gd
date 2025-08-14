extends CardEffect
class_name DefenseToHealing

const EFFECT_NAME := "Defense To Healing"

# Defense To Healing Effect - Convert block values to healing
# Theme-agnostic: recovery, regeneration, restoration, etc.

@export var conversion_ratio: float = 0.5    # Portion of block that becomes healing
@export var minimum_block: int = 0           # Minimum block required for conversion
@export var maximum_healing: int = 0         # Maximum healing per turn (0 = no limit)

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add defense-to-healing conversion to results
	if not results.has("defense_to_healing"):
		results.defense_to_healing = []
	
	results.defense_to_healing.append({
		"conversion_ratio": conversion_ratio,
		"minimum_block": minimum_block,
		"maximum_healing": maximum_healing
	})
	
	print("Applied %s effect from %s (%.1f%% conversion)" % [get_effect_name(), card_data.card_name, conversion_ratio * 100])

func get_formatted_description() -> String:
	var percentage = int(conversion_ratio * 100)
	var desc = "Your Defense cards heal you for %d%% of their block value" % percentage
	
	if minimum_block > 0:
		desc += " (minimum %d block)" % minimum_block
	if maximum_healing > 0:
		desc += " (max %d healing per turn)" % maximum_healing
	
	desc += " (Power)"
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME