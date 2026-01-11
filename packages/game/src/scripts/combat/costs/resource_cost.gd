class_name ResourceCost
extends CardCost

@export var resource_type: GameEnums.CustomResourceType
@export var amount: int = 1

func _init(p_type: GameEnums.CustomResourceType = GameEnums.CustomResourceType.NONE, p_amount: int = 1) -> void:
	resource_type = p_type
	amount = p_amount

func can_pay(source: Object) -> bool:
	if resource_type == GameEnums.CustomResourceType.NONE:
		return true
	
	var player := source as PlayerData
	if player:
		return player.get_resource(resource_type) >= amount
	
	# Enemies don't use custom resources - always affordable
	if source is EnemyState:
		return true
	
	return false

func pay(source: Object) -> void:
	if resource_type == GameEnums.CustomResourceType.NONE:
		return
	
	var player := source as PlayerData
	if player:
		player.spend_resource(resource_type, amount)
	# Enemies don't pay custom resources - no-op

func get_description() -> String:
	# Convert enum to readable string if possible, or use a helper
	var keys = GameEnums.CustomResourceType.keys()
	if resource_type >= 0 and resource_type < keys.size():
		return "%d %s" % [amount, keys[resource_type].capitalize()]
	return "%d Resource" % amount
