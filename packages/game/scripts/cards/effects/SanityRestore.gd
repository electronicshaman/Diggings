extends CardEffect
class_name SanityRestore

const EFFECT_NAME := "Sanity Restore"

@export var sanity_amount: int = 1


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add sanity restore to results
	if not results.has("sanity_restore"):
		results.sanity_restore = 0
	
	results.sanity_restore += sanity_amount
	
	print("Applied %s effect from %s (+%d sanity restore, total: %d)" % [get_effect_name(), card_data.card_name, sanity_amount, results.sanity_restore])

func get_formatted_description() -> String:
	return "Restore %d sanity" % sanity_amount

func get_effect_name() -> String:
	return EFFECT_NAME