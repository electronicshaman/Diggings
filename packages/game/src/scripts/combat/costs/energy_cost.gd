class_name EnergyCost
extends CardCost

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func can_pay(source: Object) -> bool:
	var player := source as PlayerData
	if player:
		return player.stats.current_energy >= amount
	
	var enemy := source as EnemyState
	if enemy:
		return enemy.stats.current_energy >= amount
	
	return false

func pay(source: Object) -> void:
	var player := source as PlayerData
	if player:
		player.pay_energy(amount)
		return
	
	var enemy := source as EnemyState
	if enemy:
		enemy.pay_energy(amount)

func get_description() -> String:
	return "%d Energy" % amount
