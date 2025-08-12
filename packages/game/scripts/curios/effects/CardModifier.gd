extends CurioEffect
class_name CardModifier

@export var target_card_type: String = "all"  # all, attack, skill, power, fortune, or specific card name
@export var modification_type: String = "damage"  # damage, cost, draw, return_to_hand
@export var modification_value: int = 1
@export var only_specific_card: String = ""  # If set, only affects cards with this name

func _init() -> void:
	effect_name = "Card Modifier"
	trigger_event = "card_played"
	description = _generate_description()

func apply_effect(game_state: Node, curio_data: Resource, context: Dictionary) -> void:
	var card = context.get("card", null)
	var card_data = context.get("card_data", null)
	
	if not card_data:
		return
	
	# Check if this card matches our target
	if not _matches_target(card_data):
		return
	
	# Apply the modification
	match modification_type:
		"damage":
			_modify_damage(context)
		"cost":
			_modify_cost(card_data)
		"draw":
			_trigger_draw(game_state)
		"return_to_hand":
			_return_to_hand(game_state, card)
		_:
			GLog.warn("Unknown modification type '%s'" % modification_type)

func _matches_target(card_data: CardData) -> bool:
	# Check specific card name first
	if not only_specific_card.is_empty():
		return card_data.card_name == only_specific_card
	
	# Check card type
	if target_card_type == "all":
		return true
	
	# Check mechanical category
	var category = card_data.mechanical_category if card_data.has("mechanical_category") else ""
	return category.to_lower() == target_card_type.to_lower()

func _modify_damage(context: Dictionary) -> void:
	# Add to damage in context (will be processed by combat system)
	if context.has("bonus_damage"):
		context["bonus_damage"] += modification_value
	else:
		context["bonus_damage"] = modification_value

func _modify_cost(card_data: CardData) -> void:
	# Temporarily reduce cost (would need to be handled by UI)
	card_data.energy_cost = max(0, card_data.energy_cost - modification_value)

func _trigger_draw(game_state: Node) -> void:
	if game_state.has_node("/root/DuelManager"):
		var dm = game_state.get_node("/root/DuelManager")
		if dm.has_method("draw_cards"):
			dm.draw_cards(modification_value)

func _return_to_hand(game_state: Node, card: Node) -> void:
	if card and card.has_method("return_to_hand"):
		card.return_to_hand()
	elif game_state.has_node("/root/DuelManager"):
		var dm = game_state.get_node("/root/DuelManager")
		if dm.has_method("return_card_to_hand"):
			dm.return_card_to_hand(card)

func _generate_description() -> String:
	var desc = ""
	
	# Target description
	var target_desc = target_card_type
	if not only_specific_card.is_empty():
		target_desc = only_specific_card
	elif target_card_type != "all":
		target_desc = target_card_type.capitalize() + " cards"
	else:
		target_desc = "All cards"
	
	# Modification description
	match modification_type:
		"damage":
			desc = "%s deal +%d damage" % [target_desc, modification_value]
		"cost":
			desc = "%s cost -%d energy" % [target_desc, modification_value]
		"draw":
			desc = "Draw %d card(s) when playing %s" % [modification_value, target_desc.to_lower()]
		"return_to_hand":
			desc = "%s return to hand after playing" % target_desc
	
	if super.only_first_per_turn:
		desc = "(First per turn) " + desc
	
	return desc

func get_formatted_description() -> String:
	return _generate_description()
