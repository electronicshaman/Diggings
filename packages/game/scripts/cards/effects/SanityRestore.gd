extends CardEffect
class_name SanityRestore

@export var sanity_amount: int = 1


func _init() -> void:
	effect_name = "Sanity Restore"
	description = "Restore %d sanity" % sanity_amount

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add sanity restore to results
	if not results.has("sanity_restore"):
		results.sanity_restore = 0
	
	results.sanity_restore += sanity_amount
	
	print("Applied %s effect from %s (+%d sanity restore, total: %d)" % [effect_name, card_data.card_name, sanity_amount, results.sanity_restore])

func get_formatted_description() -> String:
	return "Restore %d sanity" % sanity_amount