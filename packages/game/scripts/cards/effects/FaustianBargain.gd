extends CardEffect
class_name FaustianBargain

# Faustian Bargain - Trade max stats permanently
# "What profits a gunslinger if they gain the whole frontier but lose their soul?"

@export var health_cost: int = 0      # Max health to sacrifice
@export var energy_cost: int = 0      # Max energy to sacrifice  
@export var health_gain: int = 0      # Max health to gain
@export var energy_gain: int = 0      # Max energy to gain


func _init() -> void:
	effect_name = "Faustian Bargain"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add faustian bargain to results
	if health_cost > 0 or energy_cost > 0 or health_gain > 0 or energy_gain > 0:
		if not results.has("faustian_bargain"):
			results.faustian_bargain = []
		
		results.faustian_bargain.append({
			"health_cost": health_cost,
			"energy_cost": energy_cost,
			"health_gain": health_gain,
			"energy_gain": energy_gain
		})
		
		print("Applied %s effect from %s" % [effect_name, card_data.card_name])

func get_formatted_description() -> String:
	var parts: Array[String] = []
	
	if health_cost > 0:
		parts.append("Lose %d max health" % health_cost)
	if energy_cost > 0:
		parts.append("Lose %d max energy" % energy_cost)
	if health_gain > 0:
		parts.append("Gain %d max health" % health_gain)
	if energy_gain > 0:
		parts.append("Gain %d max energy" % energy_gain)
	
	if parts.size() > 0:
		return "FAUSTIAN BARGAIN: " + " to ".join(parts)
	return ""
