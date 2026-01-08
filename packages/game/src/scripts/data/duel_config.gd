class_name DuelConfig
extends Resource

## DuelConfig Resource
# Contains all necessary data to initialize a duel
# Passed from encounter systems to the duel scene for setup

@export var player_deck: Array[CardData] = []
@export var enemy_data: Resource = null
@export var duel_modifiers: Dictionary = {}
@export var scene_context: String = ""
@export var created_timestamp: float = 0.0

func _init(deck: Array[CardData] = [], enemy: Resource = null, context: String = "", modifiers: Dictionary = {}):
	player_deck = deck.duplicate() if deck else []
	enemy_data = enemy
	scene_context = context
	duel_modifiers = modifiers.duplicate() if modifiers else {}
	created_timestamp = Time.get_ticks_msec() / 1000.0

## Validate that the config has all required data
func is_valid() -> bool:
	if player_deck.is_empty():
		push_warning("DuelConfig: Player deck is empty")
		return false
	
	if not is_instance_valid(enemy_data):
		push_warning("DuelConfig: Enemy data is invalid")
		return false
	
	# Validate deck contents
	for card in player_deck:
		if not is_instance_valid(card):
			push_warning("DuelConfig: Player deck contains invalid card")
			return false
	
	return true

## Get validation errors for debugging
func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	
	if player_deck.is_empty():
		errors.append("Player deck is empty")
	
	if not is_instance_valid(enemy_data):
		errors.append("Enemy data is invalid")
	
	var invalid_cards = 0
	for card in player_deck:
		if not is_instance_valid(card):
			invalid_cards += 1
	
	if invalid_cards > 0:
		errors.append("Player deck contains %d invalid card(s)" % invalid_cards)
	
	if scene_context.is_empty():
		errors.append("Scene context is empty")
	
	return errors

## Get a summary of the config for debugging
func get_summary() -> Dictionary:
	var enemy_name = "Unknown"
	if is_instance_valid(enemy_data) and "enemy_name" in enemy_data:
		enemy_name = enemy_data.enemy_name
	
	return {
		"deck_size": player_deck.size(),
		"enemy_name": enemy_name,
		"context": scene_context,
		"modifiers": duel_modifiers.duplicate(),
		"created": created_timestamp,
		"valid": is_valid()
	}

## Apply any modifiers to the deck before duel start
func get_modified_deck() -> Array[CardData]:
	var modified_deck = player_deck.duplicate()
	
	# Apply deck modifiers if any
	if duel_modifiers.has("temp_cards"):
		var temp_cards = duel_modifiers.temp_cards as Array
		for card in temp_cards:
			if is_instance_valid(card):
				modified_deck.append(card)
	
	if duel_modifiers.has("removed_cards"):
		var removed_cards = duel_modifiers.removed_cards as Array
		for card_name in removed_cards:
			# Remove first instance of card with this name
			for i in range(modified_deck.size()):
				if modified_deck[i] and modified_deck[i].card_name == card_name:
					modified_deck.remove_at(i)
					break
	
	return modified_deck

## Add a temporary card modifier (doesn't affect persistent deck)
func add_temp_card(card: CardData) -> void:
	if not duel_modifiers.has("temp_cards"):
		duel_modifiers.temp_cards = []
	
	(duel_modifiers.temp_cards as Array).append(card)

## Add a card removal modifier (doesn't affect persistent deck)
func add_card_removal(card_name: String) -> void:
	if not duel_modifiers.has("removed_cards"):
		duel_modifiers.removed_cards = []
	
	(duel_modifiers.removed_cards as Array).append(card_name)

## Set a custom modifier
func set_modifier(key: String, value: Variant) -> void:
	duel_modifiers[key] = value

## Get a modifier value
func get_modifier(key: String, default_value: Variant = null) -> Variant:
	return duel_modifiers.get(key, default_value)

## Check if a modifier exists
func has_modifier(key: String) -> bool:
	return duel_modifiers.has(key)
