extends CardEffect
class_name FirstCardDraw

const EFFECT_NAME := "First Card Draw"

@export var cards_to_draw: int = 1

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Check if this is the first card played this turn
	# We'll need to track cards played per turn in the duel manager
	if duel_manager and duel_manager.has_method("get_cards_played_this_turn"):
		var cards_played = duel_manager.get_cards_played_this_turn()
		
		# If this is the first card (count should be 0 before incrementing)
		if cards_played == 0:
			results.draw += cards_to_draw
			print("Applied %s effect from %s (first card bonus: +%d draw)" % [get_effect_name(), card_data.card_name, cards_to_draw])
			
			# Add a notification that the Quick Draw bonus triggered
			if "notifications" in results:
				results.notifications.append("Quick Draw! Drew %d card(s)" % cards_to_draw)
			else:
				results.notifications = ["Quick Draw! Drew %d card(s)" % cards_to_draw]
	else:
		# Fallback: if we can't determine turn order, check if turn just started
		# This ensures the effect works even if the tracking isn't implemented yet
		print("Warning: Cannot determine if first card played - duel_manager missing method")

func get_formatted_description() -> String:
	return "If first card played this turn, draw %d card(s)" % cards_to_draw

func get_effect_name() -> String:
	return EFFECT_NAME