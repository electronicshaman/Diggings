extends Resource
class_name EffectCondition

# Condition types for when effects should activate
enum ConditionType {
	FIRST_CARD_PLAYED, # First card played this turn
	SECOND_CARD_PLAYED, # Second card played this turn
	LAST_CARD_IN_HAND, # Last card remaining in hand
	ONLY_CARD_IN_HAND, # Only one card in hand
	CARDS_PLAYED_COUNT, # Specific number of cards played this turn
	CARDS_IN_HAND_COUNT, # Specific number of cards in hand
	PLAYER_HEALTH_PERCENT, # Player health percentage threshold
	ENEMY_HEALTH_PERCENT, # Enemy health percentage threshold
	PLAYER_ENERGY_AMOUNT, # Player energy amount threshold
	PLAYER_SANITY_PERCENT, # Player sanity percentage threshold
	CUSTOM_RESOURCE_AMOUNT # Custom resource amount threshold (requires custom_resource_name)
}

@export var condition_type: ConditionType = ConditionType.FIRST_CARD_PLAYED
@export var comparison_value: int = 0 # Used for threshold/count conditions
@export var comparison_operator: String = "equal" # "equal", "less", "greater", "less_equal", "greater_equal"
@export var custom_resource_name: String = "" # Used for CUSTOM_RESOURCE_AMOUNT
@export var invert: bool = false # Invert the condition result

func evaluate(context) -> bool:
	if not context:
		return false
	
	var result = false
	
	match condition_type:
		ConditionType.FIRST_CARD_PLAYED:
			result = _get_cards_played_this_turn(context) == 0
		
		ConditionType.SECOND_CARD_PLAYED:
			result = _get_cards_played_this_turn(context) == 1
		
		ConditionType.LAST_CARD_IN_HAND:
			result = _get_cards_in_hand(context) == 1
		
		ConditionType.ONLY_CARD_IN_HAND:
			result = _get_cards_in_hand(context) == 1
		
		ConditionType.CARDS_PLAYED_COUNT:
			var played = _get_cards_played_this_turn(context)
			result = _compare_value(played, comparison_value)
		
		ConditionType.CARDS_IN_HAND_COUNT:
			var in_hand = _get_cards_in_hand(context)
			result = _compare_value(in_hand, comparison_value)
		
		ConditionType.PLAYER_HEALTH_PERCENT:
			var percent = _get_player_health_percent(context)
			result = _compare_value(percent, comparison_value)
		
		ConditionType.ENEMY_HEALTH_PERCENT:
			var percent = _get_enemy_health_percent(context)
			result = _compare_value(percent, comparison_value)
		
		ConditionType.PLAYER_ENERGY_AMOUNT:
			var energy = _get_player_energy(context)
			result = _compare_value(energy, comparison_value)
		
		ConditionType.PLAYER_SANITY_PERCENT:
			var percent = _get_player_sanity_percent(context)
			result = _compare_value(percent, comparison_value)

		ConditionType.CUSTOM_RESOURCE_AMOUNT:
			var amount = _get_custom_resource_amount(context)
			result = _compare_value(amount, comparison_value)
	
	return result if not invert else not result

func _get_cards_played_this_turn(context) -> int:
	# Handle EffectContext from new GameEffect system
	if context is Resource and context.has_method("get"):
		# Check for trigger_data dictionary containing cards_played_this_turn
		var trigger_data = context.get("trigger_data")
		if trigger_data is Dictionary and trigger_data.has("cards_played_this_turn"):
			return trigger_data["cards_played_this_turn"]
	
	# Handle Dictionary context (from legacy system)
	if context is Dictionary:
		if context.has("cards_played_this_turn"):
			return context["cards_played_this_turn"]
		elif context.has("player_data") and context["player_data"]:
			var player_data = context["player_data"]
			if player_data.has_method("get") and "cards_played_this_turn" in player_data:
				return player_data.cards_played_this_turn
	
	# Handle Resource context (legacy fallback)
	if context is Resource:
		if context.has_method("get") and context.get("cards_played_this_turn") != null:
			return context.get("cards_played_this_turn")
		
		# Fallback to player_data if available
		if context.has_method("get") and context.get("player_data"):
			var player_data = context.get("player_data")
			if player_data and player_data.has_method("get"):
				return player_data.cards_played_this_turn
	
	return 0

func _get_cards_in_hand(context) -> int:
	# Handle EffectContext from new GameEffect system
	if context is Resource and context.has_method("get"):
		# Check for trigger_data dictionary containing hand_size
		var trigger_data = context.get("trigger_data")
		if trigger_data is Dictionary and trigger_data.has("hand_size"):
			return trigger_data["hand_size"]
	
	# Handle Dictionary context (from legacy system)
	if context is Dictionary:
		if context.has("hand_size"):
			return context["hand_size"]
		elif context.has("duel_state") and context["duel_state"]:
			var duel_state = context["duel_state"]
			if duel_state.has_method("get_hand_size"):
				return duel_state.get_hand_size()
	
	# Handle Resource context (legacy fallback)
	if context is Resource:
		if context.has_method("get") and context.get("hand_size") != null:
			return context.get("hand_size")
		
		# Try to get from duel_state
		if context.has_method("get") and context.get("duel_state"):
			var duel_state = context.get("duel_state")
			if duel_state and duel_state.has_method("get_hand_size"):
				return duel_state.get_hand_size()
	
	return 0

func _get_player_health_percent(context: Resource) -> int:
	if context.has_method("get") and context.get("player_data"):
		var player_data = context.get("player_data")
		if player_data and player_data.has_method("get_health_percentage"):
			return int(player_data.get_health_percentage())
	
	return 100

func _get_enemy_health_percent(context: Resource) -> int:
	if context.has_method("get") and context.get("enemy_data"):
		var enemy_data = context.get("enemy_data")
		if enemy_data and enemy_data.has_method("get_health_percentage"):
			return int(enemy_data.get_health_percentage())
	
	return 100

func _get_player_energy(context: Resource) -> int:
	if context.has_method("get") and context.get("player_data"):
		var player_data = context.get("player_data")
		if player_data and player_data.has_method("get_current_energy"):
			return player_data.get_current_energy()
	
	return 0

func _get_player_sanity_percent(context: Resource) -> int:
	if context.has_method("get") and context.get("player_data"):
		var player_data = context.get("player_data")
		if player_data and player_data.has_method("get_sanity_percentage"):
			return int(player_data.get_sanity_percentage())
	
	return 100

func _get_custom_resource_amount(context) -> int:
	if context.has_method("get") and context.get("player_data"):
		var player_data = context.get("player_data")
		if player_data and player_data.has_method("get_custom_resource"):
			return player_data.get_custom_resource(custom_resource_name)
	return 0

func _compare_value(actual: int, expected: int) -> bool:
	match comparison_operator:
		"equal":
			return actual == expected
		"less":
			return actual < expected
		"greater":
			return actual > expected
		"less_equal":
			return actual <= expected
		"greater_equal":
			return actual >= expected
		_:
			return actual == expected

func get_description() -> String:
	var desc = ""
	
	match condition_type:
		ConditionType.FIRST_CARD_PLAYED:
			desc = "first card played this turn"
		ConditionType.SECOND_CARD_PLAYED:
			desc = "second card played this turn"
		ConditionType.LAST_CARD_IN_HAND:
			desc = "last card in hand"
		ConditionType.ONLY_CARD_IN_HAND:
			desc = "only card in hand"
		ConditionType.CARDS_PLAYED_COUNT:
			desc = "cards played this turn %s %d" % [comparison_operator, comparison_value]
		ConditionType.CARDS_IN_HAND_COUNT:
			desc = "cards in hand %s %d" % [comparison_operator, comparison_value]
		ConditionType.PLAYER_HEALTH_PERCENT:
			desc = "player health %s %d%%" % [comparison_operator, comparison_value]
		ConditionType.ENEMY_HEALTH_PERCENT:
			desc = "enemy health %s %d%%" % [comparison_operator, comparison_value]
		ConditionType.PLAYER_ENERGY_AMOUNT:
			desc = "player energy %s %d" % [comparison_operator, comparison_value]
		ConditionType.PLAYER_SANITY_PERCENT:
			desc = "player sanity %s %d%%" % [comparison_operator, comparison_value]
		ConditionType.CUSTOM_RESOURCE_AMOUNT:
			desc = "%s %s %d" % [custom_resource_name.capitalize(), comparison_operator, comparison_value]
	
	return "NOT " + desc if invert else desc
