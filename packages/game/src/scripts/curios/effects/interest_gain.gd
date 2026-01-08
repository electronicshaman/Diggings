extends CurioEffect
class_name InterestGain

const EFFECT_NAME := "Interest Gain"

@export var interest_rate: float = 0.05  # 5% interest

func _init() -> void:
	trigger_event = "combat_end"

func apply_effect(game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
	var player = _get_player_data(game_state)
	if not player or not player.stats:
		return
	
	var current_gold = player.stats.gold
	var interest = int(current_gold * interest_rate)
	
	if interest > 0:
		player.stats.gain_gold(interest)
		if game_state.has_node("/root/EventBus"):
			game_state.get_node("/root/EventBus").gold_changed.emit(interest)

func _get_player_data(game_state: Node):
	if game_state.has_method("get_player_data"):
		return game_state.get_player_data()
	elif game_state.has_node("/root/GameManager"):
		var gm = game_state.get_node("/root/GameManager")
		if gm.game_data.has("player"):
			return gm.game_data["player"]
	return null

func get_effect_name() -> String:
	return EFFECT_NAME
