extends Resource
class_name EncounterChoice

const DEBUG_ENABLED: bool = true

@export var choice_text: String = "Choose"
@export_multiline var choice_description: String = ""
@export var choice_icon: Texture2D

@export_group("Requirements")
@export var gold_cost: int = 0
@export var sanity_cost: int = 0
@export var corruption_cost: int = 0
@export var health_cost: int = 0
@export var required_item: String = ""
@export var required_class: String = ""
@export var min_stat_requirement: Dictionary = {}

@export_group("Outcomes")
@export var outcomes: Array[Resource] = [] # EffectHandler resources
@export var success_chance: float = 1.0
@export var failure_outcomes: Array[Resource] = [] # EffectHandler resources

@export_group("Conditions")
@export var is_hidden: bool = false
@export var show_requirements: bool = true
@export var one_time_only: bool = false

@export_group("Visual")
@export var highlight_color: Color = Color.WHITE
@export var disabled_color: Color = Color(0.5, 0.5, 0.5, 0.7)

func can_select(game_state: Dictionary) -> bool:
	if gold_cost > 0 and game_state.get("gold", 0) < gold_cost:
		return false
	
	if sanity_cost > 0 and game_state.get("sanity", 100) < sanity_cost:
		return false
	
	if corruption_cost > 0 and game_state.get("max_corruption", 100) - game_state.get("corruption", 0) < corruption_cost:
		return false
	
	if health_cost > 0 and game_state.get("health", 0) <= health_cost:
		return false
	
	if required_item != "" and not required_item in game_state.get("curios", []):
		return false
	
	if required_class != "" and game_state.get("character_class", "") != required_class:
		return false
	
	for stat_name in min_stat_requirement:
		var required_value = min_stat_requirement[stat_name]
		var current_value = game_state.get(stat_name, 0)
		if current_value < required_value:
			return false
	
	return true

func get_formatted_text(game_state: Dictionary = {}) -> String:
	var formatted = choice_text
	
	if show_requirements and not can_select(game_state):
		var requirements = []
		
		if gold_cost > 0:
			requirements.append("[color=yellow]%d gold[/color]" % gold_cost)
		if sanity_cost > 0:
			requirements.append("[color=cyan]%d sanity[/color]" % sanity_cost)
		if corruption_cost > 0:
			requirements.append("[color=purple]%d corruption[/color]" % corruption_cost)
		if health_cost > 0:
			requirements.append("[color=red]%d health[/color]" % health_cost)
		if required_item != "":
			requirements.append("[color=orange]Requires: %s[/color]" % required_item)
		if required_class != "":
			requirements.append("[color=green]%s only[/color]" % required_class)
		
		if not requirements.is_empty():
			formatted += " (" + ", ".join(requirements) + ")"
	
	return formatted

func get_display_color(can_afford: bool) -> Color:
	if not can_afford:
		return disabled_color
	return highlight_color

func apply_costs(game_state: Dictionary) -> void:
	if gold_cost > 0:
		game_state["gold"] = max(0, game_state.get("gold", 0) - gold_cost)
	
	if sanity_cost > 0:
		game_state["sanity"] = max(0, game_state.get("sanity", 100) - sanity_cost)
	
	if corruption_cost > 0:
		game_state["corruption"] = min(game_state.get("max_corruption", 100),
			game_state.get("corruption", 0) + corruption_cost)
	
	if health_cost > 0:
		game_state["health"] = max(0, game_state.get("health", 0) - health_cost)

func get_outcomes_to_apply(rng_result: float = randf()) -> Array[Resource]:
	if rng_result <= success_chance:
		return outcomes
	else:
		return failure_outcomes if not failure_outcomes.is_empty() else []

func has_random_outcome() -> bool:
	return success_chance < 1.0 and not failure_outcomes.is_empty()

func get_success_percentage() -> int:
	return int(success_chance * 100)

func get_outcome_preview() -> String:
	var preview_parts = []
	
	for outcome in outcomes:
		if outcome and outcome.has_method("get_description_text"):
			var preview = outcome.get_description_text()
			if preview != "":
				preview_parts.append(preview)
		elif outcome and outcome.has_method("get_preview_text"):
			# Deprecated: kept for backward compatibility
			var preview = outcome.get_preview_text()
			if preview != "":
				preview_parts.append(preview)
	
	if has_random_outcome():
		preview_parts.append("(%d%% chance)" % get_success_percentage())
	
	return ", ".join(preview_parts) if not preview_parts.is_empty() else ""