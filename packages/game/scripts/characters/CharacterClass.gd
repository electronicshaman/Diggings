extends Resource
class_name CharacterClass

@export var character_class_name: String = "Bushranger"
@export var description: String = "An outlaw of the Australian bush"
@export var starting_health_bonus: int = 0
@export var starting_energy_bonus: int = 0
@export var starting_deck: Array[CardData] = []

func get_display_name() -> String:
	return character_class_name