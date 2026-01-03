extends Node
class_name CardEffects

const DEBUG_ENABLED: bool = true

## Safe property existence helper (Resources/Objects don't have has_property())
func _has_prop(obj, prop_name: String) -> bool:
	if obj == null:
		return false
	if obj is Dictionary:
		return (obj as Dictionary).has(prop_name)
	if obj is Object:
		var o: Object = obj
		var plist: Array = o.get_property_list()
		for p in plist:
			if typeof(p) == TYPE_DICTIONARY and (p as Dictionary).get("name", "") == prop_name:
				return true
	return false

func apply_card_instance_effects(duel_manager: DuelManager, card_instance: CardInstance) -> Dictionary:
	# Create default results dictionary
	var results = _create_default_results()
	
	# Validate inputs
	var validation_result = _validate_card_effect_inputs(duel_manager, card_instance.card_data)
	if validation_result.error != OK:
		push_error("CardEffects: Cannot apply effects - %s" % validation_result.message)
		return results
	
	# Process effects safely
	var processed_effects = 0
	var failed_effects = 0
	
	if DEBUG_ENABLED:
		GLog.debug("Processing %d effects for card: %s" % [card_instance.card_data.effects.size(), card_instance.get_card_name()])
	
	for i in range(card_instance.card_data.effects.size()):
		var effect = card_instance.card_data.effects[i]
		
		var effect_result = _apply_single_effect(effect, duel_manager, card_instance, results, i)
		if effect_result.success:
			processed_effects += 1
		else:
			failed_effects += 1
			if DEBUG_ENABLED:
				GLog.warn("Effect %d failed: %s" % [i, effect_result.error_message])
	
	# Apply gambling modifiers if applicable
	_apply_gambling_modifiers(duel_manager, results)
	
	# Log final results
	if failed_effects > 0:
		push_warning("CardEffects: %d/%d effects failed for card: %s" % [
			failed_effects,
			card_instance.card_data.effects.size(),
			card_instance.get_card_name()
		])
	
	if DEBUG_ENABLED:
		GLog.debug("Card effects complete: %d processed, %d failed" % [processed_effects, failed_effects])
	
	return results

func apply_card_instance_effects_with_context(duel_manager: DuelManager, card_instance: CardInstance, cards_played_before: int, hand_size_before: int) -> Dictionary:
	# Create default results dictionary
	var results = _create_default_results()
	
	# Validate inputs
	var validation_result = _validate_card_effect_inputs(duel_manager, card_instance.card_data)
	if validation_result.error != OK:
		push_error("CardEffects: Cannot apply effects - %s" % validation_result.message)
		return results
	
	# Create effect context with timing information
	var context = _create_effect_context(duel_manager, card_instance, cards_played_before, hand_size_before)
	
	# Process effects safely
	var processed_effects = 0
	var failed_effects = 0
	
	if DEBUG_ENABLED:
		GLog.debug("Processing %d effects for card: %s (cards played before: %d, hand size before: %d)" % [
			card_instance.card_data.effects.size(), card_instance.get_card_name(), cards_played_before, hand_size_before
		])
	
	for i in range(card_instance.card_data.effects.size()):
		var effect = card_instance.card_data.effects[i]
		
		var effect_result = _apply_single_effect_with_context(effect, duel_manager, card_instance, results, context, i)
		if effect_result.success:
			processed_effects += 1
		else:
			failed_effects += 1
			if DEBUG_ENABLED:
				GLog.warn("Effect %d failed: %s" % [i, effect_result.error_message])
	
	# Apply gambling modifiers if applicable
	_apply_gambling_modifiers(duel_manager, results)
	
	# Log final results
	if failed_effects > 0:
		push_warning("CardEffects: %d/%d effects failed for card: %s" % [
			failed_effects,
			card_instance.card_data.effects.size(),
			card_instance.get_card_name()
		])
	
	if DEBUG_ENABLED:
		GLog.debug("Card effects complete: %d processed, %d failed" % [processed_effects, failed_effects])
	
	return results

## Create default results dictionary
func _create_default_results() -> Dictionary:
	return {
		"damage": 0,
		"defense": 0,
		"heal": 0,
		"draw": 0,
		"energy_restore": 0,
		"stun_enemy": 0,
		"ignores_defense": false,
		"discard_random": 0,
		"add_curse": 0,
		"sanity_restore": 0,
		"exhaust_random": 0
	}

## Validate inputs for card effect application
func _validate_card_effect_inputs(duel_manager: DuelManager, card_data: CardData) -> Dictionary:
	var result = {"error": OK, "message": ""}
	
	# Validate duel manager
	if not is_instance_valid(duel_manager):
		result.error = ERR_INVALID_PARAMETER
		result.message = "DuelManager is invalid"
		return result
	
	# Check for required methods on duel manager
	var required_duel_methods = ["get_player_data", "get_enemy_data"]
	for method in required_duel_methods:
		if not duel_manager.has_method(method):
			result.error = ERR_METHOD_NOT_FOUND
			result.message = "DuelManager missing method: " + method
			return result
	
	# Validate card data
	if not is_instance_valid(card_data):
		result.error = ERR_INVALID_PARAMETER
		result.message = "CardData is invalid"
		return result
	
	# Check for required properties on card data
	var required_card_properties = ["card_name", "effects"]
	for prop in required_card_properties:
		if not _has_prop(card_data, prop):
			result.error = ERR_INVALID_DATA
			result.message = "CardData missing property: " + prop
			return result
	
	# Validate effects array
	if not card_data.effects is Array:
		result.error = ERR_INVALID_DATA
		result.message = "Card effects is not an array"
		return result
	
	# Check duel state
	if not is_instance_valid(duel_manager.duel_state):
		result.error = ERR_INVALID_DATA
		result.message = "DuelManager has invalid duel_state"
		return result
	
	return result

## Apply a single effect with error handling
func _apply_single_effect(effect: Resource, duel_manager: DuelManager, card_instance: CardInstance, results: Dictionary, effect_index: int) -> Dictionary:
	var result = {"success": false, "error_message": ""}

	# Validate effect
	if not is_instance_valid(effect):
		result.error_message = "Effect %d is invalid" % effect_index
		return result

	# Create context for effect evaluation
	var context = _create_effect_context(duel_manager, card_instance, 0, 0)

	# All effects are now GameEffect
	if not effect is GameEffect:
		result.error_message = "Effect %d is not a GameEffect" % effect_index
		return result

	# Check if effect can be applied
	var can_apply: bool = true
	if effect.has_method("can_apply"):
		can_apply = effect.can_apply(context)

	if not can_apply:
		result.error_message = "Effect %d cannot be applied in current context" % effect_index
		return result

	# Apply GameEffect
	if effect.has_method("apply_effect"):
		var effect_result = effect.apply_effect(context)
		if effect_result and effect_result is EffectResult and effect_result.success:
			_merge_effect_result_into_results(effect_result, results)
			result.success = true
		else:
			result.error_message = "GameEffect failed to apply"
	else:
		result.error_message = "Effect %d has no apply_effect method" % effect_index

	var effect_name = "GameEffect"
	if effect.has_method("get_effect_name"):
		effect_name = effect.get_effect_name()

	if DEBUG_ENABLED:
		GLog.debug("Applied effect: %s" % effect_name)

	return result

## Apply gambling modifiers safely
func _apply_gambling_modifiers(duel_manager: DuelManager, results: Dictionary) -> void:
	if not is_instance_valid(duel_manager):
		return

	if not is_instance_valid(duel_manager.duel_state):
		return

	if not is_instance_valid(duel_manager.duel_state.player_data):
		return
	
	var player_data = duel_manager.duel_state.player_data
	
	if not player_data.has_method("check_and_apply_gambling"):
		if DEBUG_ENABLED:
			GLog.debug("Player data does not support gambling mechanics")
		return
	
	var gambling_result = player_data.check_and_apply_gambling()
	
	if not gambling_result is Dictionary or not gambling_result.has("active"):
		if DEBUG_ENABLED:
			GLog.warn("Invalid gambling result format")
		return
	
	if gambling_result.active:
		var multiplier = gambling_result.get("multiplier", 1.0)
		if DEBUG_ENABLED:
			GLog.debug("Gambling active! Multiplier: %.1fx" % multiplier)

		# Base 50% chance for gambling success
		# Holy Conviction (Preacher passive): +10% if Faith >= 5
		var success_chance = 0.5
		if _is_preacher_with_high_faith(player_data):
			success_chance = 0.6
			if DEBUG_ENABLED:
				GLog.debug("Holy Conviction active! Fortune success chance: 60%")

		if randf() < success_chance:
			# Apply multiplier to relevant results
			var multiplied_fields = ["damage", "defense", "heal"]
			for field in multiplied_fields:
				if results.has(field) and results[field] is int:
					results[field] = int(results[field] * multiplier)
			
			if DEBUG_ENABLED:
				GLog.debug("Gambling SUCCESS! Effects multiplied by %.1fx" % multiplier)
		else:
			# Negate effects on gambling failure
			results.damage = 0
			results.defense = 0
			results.heal = 0
			if DEBUG_ENABLED:
				GLog.debug("Gambling FAILED! All effects negated")

func _is_preacher_with_high_faith(player_data) -> bool:
	"""Check if player is Preacher with Faith >= 5 (for Holy Conviction passive)"""
	if not player_data:
		return false

	# Check if Preacher
	var is_preacher = false
	if player_data.character_class and player_data.character_class.character_class_name == "Preacher":
		is_preacher = true
	elif player_data.character_class_name == "Preacher":
		is_preacher = true

	if not is_preacher:
		return false

	# Check if Faith >= 5
	if player_data.has("faith") and player_data.faith >= 5:
		return true

	return false

func get_card_value_estimate(card_data: CardData) -> int:
	# Input validation
	if not is_instance_valid(card_data):
		push_error("CardEffects: Cannot estimate value - card_data is invalid")
		return 0
	
	var value = 0
	
	# Validate effects array
	if not (card_data.effects is Array):
		push_warning("CardEffects: Card has no valid effects array for value estimation")
		return 0
	
	# Safely evaluate each effect
	for effect in card_data.effects:
		if not is_instance_valid(effect):
			continue
		
		var effect_value = _calculate_effect_value(effect)
		value += effect_value
	
	# Subtract costs if available
	if _has_prop(card_data, "energy_cost") and card_data.energy_cost is int:
		value -= card_data.energy_cost * 2
	
	if _has_prop(card_data, "sanity_cost") and card_data.sanity_cost is int:
		value -= card_data.sanity_cost
	
	return max(0, value)  # Ensure non-negative value

## Calculate value contribution of a single effect
func _calculate_effect_value(effect: Resource) -> int:
	if not is_instance_valid(effect):
		return 0

	var value = 0

	# All effects are now GameEffect
	if effect is GameEffect:
		if _has_prop(effect, "amount"):
			value = effect.amount * 2
		elif _has_prop(effect, "base_value"):
			value = effect.base_value * 2
		else:
			value = 3  # Base value for unknown GameEffect
	else:
		value = 1  # Fallback for any unexpected effect type

	return value

## Validate effect results dictionary
func validate_effect_results(results: Dictionary) -> bool:
	if results.is_empty():
		return false
	
	var required_keys = ["damage", "defense", "heal", "draw", "energy_restore", "stun_enemy", "ignores_defense", "discard_random", "add_curse", "sanity_restore"]
	
	for key in required_keys:
		if not results.has(key):
			push_warning("CardEffects: Results missing key: " + key)
			return false
	
	return true

## Get effect processing diagnostics
func get_effect_diagnostics(card_data: CardData) -> Dictionary:
	var diagnostics = {
		"valid_card": is_instance_valid(card_data),
		"effect_count": 0,
		"valid_effects": 0,
		"effect_types": []
	}
	
	if not is_instance_valid(card_data) or not (card_data.effects is Array):
		return diagnostics
	
	diagnostics.effect_count = card_data.effects.size()
	
	for effect in card_data.effects:
		if is_instance_valid(effect):
			diagnostics.valid_effects += 1
			diagnostics.effect_types.append(effect.get_script().get_path().get_file().get_basename())
	
	return diagnostics

## Create effect context for conditional evaluation
func _create_effect_context(duel_manager: DuelManager, card_instance: CardInstance, cards_played_before: int, hand_size_before: int) -> EffectContext:
	var context = EffectContext.new()
	
	# Set source information
	context.source_type = "card"
	context.source_object = card_instance.card_data if card_instance else null
	
	# Set state references
	context.game_manager = null  # TODO: Get from duel_manager if available
	context.duel_manager = duel_manager
	context.player_data = duel_manager.duel_state.player_data if duel_manager.duel_state else null
	context.enemy_data = duel_manager.duel_state.enemy_data if duel_manager.duel_state else null
	
	# Set trigger information
	context.trigger_event = "card_played"
	context.trigger_data = {
		"cards_played_this_turn": cards_played_before,
		"hand_size": hand_size_before,
		"card_instance": card_instance,
		"duel_state": duel_manager.duel_state
	}

	# Set targeting: need to account for whether this card is owned by the player or enemy
	var is_player_owned = false
	if card_instance:
		is_player_owned = card_instance.owner == CardInstance.Owner.PLAYER
		var card_type = card_instance.card_data.get_mechanical_category() if card_instance.card_data else ""
		# If attack: player-owned targets enemy, enemy-owned targets player
		if card_type == "Attack":
			context.primary_target = context.enemy_data if is_player_owned else context.player_data
		else:
			# Non-attack cards typically target self side
			context.primary_target = context.player_data if is_player_owned else context.enemy_data

	# Add curio modifications to context for effect application
	# Only apply curio modifications to player cards
	if CurioManager and context.source_object:
		context.curio_modifications = CurioManager.calculate_card_modifications(context.source_object, is_player_owned)
	
	return context

## Apply a single effect with context for conditional evaluation
func _apply_single_effect_with_context(effect: Resource, duel_manager: DuelManager, card_instance: CardInstance, results: Dictionary, context: EffectContext, effect_index: int) -> Dictionary:
	var result = {"success": false, "error_message": ""}

	# Validate effect
	if not is_instance_valid(effect):
		result.error_message = "Effect %d is invalid" % effect_index
		return result

	# All effects are now GameEffect
	if not effect is GameEffect:
		result.error_message = "Effect %d is not a GameEffect" % effect_index
		return result

	# Check if effect can be applied
	var can_apply: bool = true
	if effect.has_method("can_apply"):
		can_apply = effect.can_apply(context)

	if not can_apply:
		result.error_message = "Effect %d cannot be applied in current context" % effect_index
		return result

	# Apply GameEffect
	if effect.has_method("apply_effect"):
		var effect_result = effect.apply_effect(context)
		if effect_result and effect_result is EffectResult and effect_result.success:
			_merge_effect_result_into_results(effect_result, results)
			result.success = true
		else:
			result.error_message = "GameEffect failed to apply"
	else:
		result.error_message = "Effect %d has no apply_effect method" % effect_index

	return result

## Helper to merge GameEffect results into results dictionary
func _merge_effect_result_into_results(effect_result: Resource, results: Dictionary) -> void:
	if not effect_result or not effect_result is EffectResult:
		return

	var values_applied = effect_result.values_applied
	if not values_applied is Dictionary:
		return

	for key in values_applied.keys():
		match key:
			"damage":
				if values_applied[key] > 0:
					results.damage += values_applied[key]
			"damage_hits":
				if values_applied[key] > 0:
					results.damage_hits = int(values_applied[key])
			"heal":
				if values_applied[key] > 0:
					results.heal += values_applied[key]
			"defense":
				if values_applied[key] > 0:
					results.defense += values_applied[key]
			"delayed_defense":
				# Store delayed defense for next turn processing
				if not results.has("delayed_defense"):
					results.delayed_defense = []
				results.delayed_defense.append_array(values_applied[key])
			"drawn":
				if values_applied[key] > 0:
					results.draw += values_applied[key]
			"discard_random":
				if values_applied[key] > 0:
					results.discard_random += values_applied[key]
			"exhaust_random":
				if values_applied[key] > 0:
					results.exhaust_random += values_applied[key]
			"shuffle_deck":
				results.shuffle_deck = values_applied[key]
			"ignores_defense":
				if values_applied[key]:
					results.ignores_defense = true
			"stun_enemy":
				if values_applied[key] > 0:
					results.stun_enemy += values_applied[key]
			"enemy_debuff":
				if not results.has("enemy_debuff"):
					results.enemy_debuff = []
				results.enemy_debuff.append(values_applied[key])
			"energy":
				if values_applied[key] != 0:
					results.energy_restore += values_applied[key]
			"sanity":
				if values_applied[key] > 0:
					results.sanity_restore += values_applied[key]
			"gold":
				if not results.has("gold"):
					results.gold = 0
				results.gold += values_applied[key]
