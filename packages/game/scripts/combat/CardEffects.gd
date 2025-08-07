extends Node
class_name CardEffects

func apply_card_effects(duel_manager: DuelManager, card_data: CardData) -> Dictionary:
	var results = {
		"damage": 0,
		"defense": 0,
		"heal": 0,
		"draw": 0,
		"energy_restore": 0,
		"stun_enemy": 0,
		"ignores_defense": false,
		"discard_random": 0,
		"add_curse": 0,
		"sanity_restore": 0
	}
	
	print("Processing %d effects for card: %s" % [card_data.effects.size(), card_data.card_name])
	
	for effect in card_data.effects:
		if effect and effect.can_apply(duel_manager, card_data):
			effect.apply_effect(duel_manager, card_data, results)
			print("Applied effect: %s" % effect.effect_name)
	
	var player_data = duel_manager.duel_state.player_data
	var gambling_result = player_data.check_and_apply_gambling()
	if gambling_result.active:
		print("Gambling active! Multiplier: %.1fx" % gambling_result.multiplier)
		
		if randf() < 0.5:
			results.damage = int(results.damage * gambling_result.multiplier)
			results.defense = int(results.defense * gambling_result.multiplier)
			results.heal = int(results.heal * gambling_result.multiplier)
			print("Gambling SUCCESS! Effects multiplied by %.1fx" % gambling_result.multiplier)
		else:
			results.damage = 0
			results.defense = 0
			results.heal = 0
			print("Gambling FAILED! All effects negated")
	
	return results

func get_card_value_estimate(card_data: CardData) -> int:
	var value = 0
	
	for effect in card_data.effects:
		if effect is Damage:
			value += effect.damage_amount * 2
		elif effect is Defense:
			value += effect.defense_amount * 2
		elif effect is Heal:
			value += effect.heal_amount * 3
		elif effect is Draw:
			value += effect.cards_to_draw * 3
		elif effect is Stun:
			value += effect.stun_duration * 4
	
	value -= card_data.energy_cost * 2
	value -= card_data.sanity_cost
	
	return value