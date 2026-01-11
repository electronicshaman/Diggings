class_name SanityCost
extends CardCost

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func can_pay(source: Object) -> bool:
	var player := source as PlayerData
	if player:
		return player.stats.current_sanity >= amount
	
	# Enemies don't use sanity - always affordable
	if source is EnemyState:
		return true
	
	return false

func pay(source: Object) -> void:
	var player := source as PlayerData
	if player:
		player.pay_sanity(amount)
	# Enemies don't pay sanity - no-op

func get_description() -> String:
	return "%d Sanity" % amount
