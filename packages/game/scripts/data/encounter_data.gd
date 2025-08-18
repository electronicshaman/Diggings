extends Resource
class_name EncounterData

const DEBUG_ENABLED: bool = true

@export var encounter_id: String
@export var encounter_name: String = "Encounter"
@export_multiline var description: String = ""
@export var encounter_icon: Texture2D
@export_multiline var flavor_text: String = ""

@export_group("Event Properties")
@export_enum("Common", "Rare", "Legendary", "Story") var rarity: String = "Common"
@export_enum("Neutral", "Positive", "Negative", "Mixed") var encounter_type: String = "Neutral"
@export var repeatable: bool = true
@export var max_occurrences: int = -1
@export var weight: float = 1.0

@export_group("Choices")
@export var choices: Array[EncounterChoice] = []

@export_group("Requirements")
@export var min_gold: int = -1
@export var max_gold: int = -1
@export var min_corruption: int = -1
@export var max_corruption: int = -1
@export var min_sanity: int = -1
@export var max_sanity: int = -1
@export var required_classes: Array[String] = []
@export var excluded_classes: Array[String] = []
@export var required_curios: Array[String] = []
@export var required_cards: Array[String] = []
@export var min_act: int = 1
@export var max_act: int = -1

@export_group("Regional Affinity")
@export var regional_weights: Dictionary = {
	"goldfields": 1.0,
	"outback": 1.0,
	"mountains": 1.0,
	"coast": 1.0
}

@export_group("Visual")
@export var background_image: Texture2D
@export var ambient_sound: AudioStream
@export var encounter_color: Color = Color.WHITE

func _init():
	if not encounter_id:
		encounter_id = str(hash(self))
	encounter_id = encounter_id.strip_edges()

func get_encounter_id() -> String:
	return encounter_id

func can_trigger(game_state: Dictionary) -> bool:
	if min_gold >= 0 and game_state.get("gold", 0) < min_gold:
		return false
	if max_gold >= 0 and game_state.get("gold", 0) > max_gold:
		return false
	
	if min_corruption >= 0 and game_state.get("corruption", 0) < min_corruption:
		return false
	if max_corruption >= 0 and game_state.get("corruption", 0) > max_corruption:
		return false
	
	if min_sanity >= 0 and game_state.get("sanity", 100) < min_sanity:
		return false
	if max_sanity >= 0 and game_state.get("sanity", 100) > max_sanity:
		return false
	
	var current_class = game_state.get("character_class", "")
	if not required_classes.is_empty() and not current_class in required_classes:
		return false
	if not excluded_classes.is_empty() and current_class in excluded_classes:
		return false
	
	var player_curios = game_state.get("curios", [])
	for required_curio in required_curios:
		if not required_curio in player_curios:
			return false
	
	var player_cards = game_state.get("deck", [])
	for required_card in required_cards:
		var has_card = false
		for card in player_cards:
			if card.card_name == required_card:
				has_card = true
				break
		if not has_card:
			return false
	
	var current_act = game_state.get("act", 1)
	if current_act < min_act:
		return false
	if max_act >= 0 and current_act > max_act:
		return false
	
	return true

func get_available_choices(game_state: Dictionary) -> Array[EncounterChoice]:
	var available: Array[EncounterChoice] = []
	for choice in choices:
		if choice and choice.can_select(game_state):
			available.append(choice)
	return available

func get_weight_for_region(region: String) -> float:
	return regional_weights.get(region, 1.0) * weight

func get_formatted_description(game_state: Dictionary = {}) -> String:
	var formatted = description
	
	formatted = formatted.replace("{player_name}", game_state.get("player_name", "Adventurer"))
	formatted = formatted.replace("{character_class}", game_state.get("character_class", "Wanderer"))
	formatted = formatted.replace("{gold}", str(game_state.get("gold", 0)))
	formatted = formatted.replace("{corruption}", str(game_state.get("corruption", 0)))
	formatted = formatted.replace("{sanity}", str(game_state.get("sanity", 100)))
	formatted = formatted.replace("{act}", str(game_state.get("act", 1)))
	formatted = formatted.replace("{region}", game_state.get("region", "the wilderness"))
	
	return formatted

func get_rarity_color() -> Color:
	match rarity:
		"Common":
			return Color.GRAY
		"Rare":
			return Color.CYAN
		"Legendary":
			return Color.GOLD
		"Story":
			return Color.PURPLE
		_:
			return Color.WHITE

func get_type_icon() -> String:
	match encounter_type:
		"Positive":
			return "✨"
		"Negative":
			return "💀"
		"Mixed":
			return "⚖️"
		_:
			return "❓"

func is_story_encounter() -> bool:
	return rarity == "Story"

func is_repeatable() -> bool:
	return repeatable and (max_occurrences < 0 or max_occurrences > 1)
