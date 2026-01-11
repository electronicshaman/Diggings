class_name CardCost
extends Resource

## Base class for all card costs (Energy, Sanity, Resources)

func can_pay(source: Object) -> bool:
	return true

func pay(source: Object) -> void:
	pass

func get_description() -> String:
	return ""
