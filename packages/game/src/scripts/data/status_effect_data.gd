extends Resource
class_name StatusEffectData
## Data definition for a status effect type.
## Each status effect has its own .tres resource file defining its behavior.

const DEBUG_ENABLED: bool = false

## Unique identifier for this status effect (e.g., "poison", "grit")
@export var effect_id: String = ""

## Display name for UI (e.g., "Poison", "Grit")
@export var display_name: String = ""

## Icon texture for status display
@export var icon: Texture2D

## Description template. Supports {stacks} and {value} placeholders
@export_multiline var description_template: String = ""

## Is this a buff (positive) or debuff (negative)?
@export var is_buff: bool = false

## Can this effect stack (increase stack count)?
@export var stackable: bool = true

## Maximum stack count (0 = unlimited, default 99)
@export var max_stacks: int = 99

## Stack behavior when effect is reapplied
@export_enum("add_stacks", "refresh_duration", "take_higher") var stack_behavior: String = "add_stacks"

## When stacks decay
@export_enum("none", "per_turn_start", "per_turn_end", "on_trigger") var decay_type: String = "per_turn_end"

## Amount to decay per trigger
@export var decay_amount: int = 1

## Is this effect fully consumed when triggered (like Surge, Burn)?
@export var consumed_on_trigger: bool = false

## When this effect triggers/is checked
@export_enum("turn_start", "turn_end", "on_attack", "on_defend", "on_damage_taken", "on_resource_gain", "on_card_play", "passive") var trigger_phase: String = "passive"

## Type of effect for processing
@export_enum("damage", "heal", "sanity_damage", "sanity_heal", "energy_gain", "draw_modifier", "damage_modifier", "defense_modifier", "damage_taken_modifier", "resource_gain_modifier", "card_blocker", "reflection", "lifesteal") var effect_type: String = "damage"

## Base value per stack (interpretation depends on effect_type)
## For flat bonuses: actual value per stack (e.g., 1 for Grit = +1 damage)
## For percentages: decimal value (e.g., 0.05 for Thorns = 5% per stack)
@export var value_per_stack: float = 1.0

## Is this a percentage-based effect?
@export var is_percentage: bool = false

## Maximum percentage for percentage-based effects (e.g., 1.0 = 100% cap for Thorns/Drain)
@export var percentage_cap: float = 1.0

## Visual effect color for UI and particles
@export var effect_color: Color = Color.WHITE


## Returns the description with placeholders replaced
func get_description(stacks: int = 1) -> String:
	var desc := description_template
	desc = desc.replace("{stacks}", str(stacks))
	desc = desc.replace("{value}", str(int(value_per_stack * stacks)))
	if is_percentage:
		var percent := minf(value_per_stack * stacks, percentage_cap) * 100.0
		desc = desc.replace("{percent}", "%.0f%%" % percent)
	return desc


## Calculate the total value for a given stack count
func calculate_value(stacks: int) -> float:
	var total := value_per_stack * stacks
	if is_percentage:
		total = minf(total, percentage_cap)
	return total


## Check if this effect should decay at the given phase
func should_decay_at(phase: String) -> bool:
	return decay_type == phase


## Check if this effect triggers at the given phase
func triggers_at(phase: String) -> bool:
	return trigger_phase == phase
