extends CardEffect
class_name AddCurse

# Add Curse Effect - Adds curse cards to deck as negative consequence
# "Power always comes with a price"

@export var curse_card_name: String = "Misfire"  # Name of curse card to add
@export var copies_to_add: int = 1               # How many copies to add


func _init() -> void:
	effect_name = "Add Curse"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add curse to results
	if not results.has("add_curse"):
		results.add_curse = []
	
	results.add_curse.append({
		"curse_name": curse_card_name,
		"copies": copies_to_add
	})
	
	print("Applied %s effect from %s (adding %d %s cards)" % [effect_name, card_data.card_name, copies_to_add, curse_card_name])

func get_formatted_description() -> String:
	if copies_to_add == 1:
		return "Add '%s' to deck" % curse_card_name
	else:
		return "Add %d '%s' cards to deck" % [copies_to_add, curse_card_name]
