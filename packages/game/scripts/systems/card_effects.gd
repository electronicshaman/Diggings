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
		"sanity_restore": 0
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
	var context = _create_effect_context(duel_manager, card_instance, 0, 0)  # Default context for non-context calls
	
	# Handle both GameEffect (EffectContext) and legacy CardEffect systems
	if effect is GameEffect:
		# GameEffect: Use EffectContext
		var can_apply: bool = true
		if effect.has_method("can_apply"):
			can_apply = effect.can_apply(context)

		if not can_apply:
			result.error_message = "Effect %d cannot be applied in current context" % effect_index
			return result

		# Apply GameEffect with EffectContext
		if effect.has_method("apply_effect"):
			var effect_result = effect.apply_effect(context)
			if effect_result and effect_result.has_method("get") and effect_result.get("success"):
				# Merge effect results into main results dictionary
				_merge_effect_result_into_results(effect_result, results)
				result.success = true
			else:
				result.error_message = "GameEffect failed to apply"
		else:
			result.error_message = "Effect %d has no applicable apply method" % effect_index
	
	else:
		# Legacy CardEffect: Use traditional method calls
		if effect.has_method("apply_effect_with_instance"):
			effect.apply_effect_with_instance(context.duel_manager, card_instance, results)
			result.success = true
		elif effect.has_method("apply_effect"):
			effect.apply_effect(context.duel_manager, card_instance.card_data, results)
			result.success = true
		else:
			result.error_message = "Legacy effect %d has no applicable apply method" % effect_index
	
	var effect_name = "Unknown"
	if effect.has_method("get_effect_name"):
		effect_name = effect.get_effect_name()
	elif effect is GameEffect:
		effect_name = "GameEffect"
	elif effect is CardEffect:
		effect_name = "CardEffect"
	
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
		
		# 50% chance for gambling success
		if randf() < 0.5:
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
	
	# Handle both GameEffect and legacy CardEffect types
	if effect is GameEffect:
		# GameEffect value estimation
		if _has_prop(effect, "amount"):
			value = effect.amount * 2  # Generic multiplier
		elif _has_prop(effect, "base_value"):
			value = effect.base_value * 2
		else:
			# Fallback to generic effect value
			value = 3  # Base value for GameEffect
	else:
		# Legacy CardEffect value estimation
		if effect is Damage and _has_prop(effect, "damage_amount"):
			value = effect.damage_amount * 2
		elif effect is RandomDamage and _has_prop(effect, "min_damage") and _has_prop(effect, "max_damage"):
			var avg_damage = (effect.min_damage + effect.max_damage) / 2.0
			value = int(avg_damage * 2)
		elif effect is Defense and _has_prop(effect, "defense_amount"):
			value = effect.defense_amount * 2
		elif effect is Heal and _has_prop(effect, "heal_amount"):
			value = effect.heal_amount * 3
		elif effect is Draw and _has_prop(effect, "cards_to_draw"):
			value = effect.cards_to_draw * 3
		elif effect is Stun and _has_prop(effect, "stun_duration"):
			value = effect.stun_duration * 4
		else:
			# Generic effect value estimation
			value = 1  # Base value for unknown effects
	
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
	if card_instance and card_instance.card_data:
		var card_type = card_instance.card_data.get_mechanical_category()
		var is_player_owned = false
		# Heuristic: reuse duel_manager._is_player_card if available
		if duel_manager and duel_manager.has_method("_is_player_card"):
			is_player_owned = duel_manager._is_player_card(card_instance.card_data)
		# If attack: player-owned targets enemy, enemy-owned targets player
		if card_type == "Attack":
			context.primary_target = context.enemy_data if is_player_owned else context.player_data
		else:
			# Non-attack cards typically target self side
			context.primary_target = context.player_data if is_player_owned else context.enemy_data
	
	return context

## Convert EffectContext to Dictionary for legacy CardEffect compatibility
func _effect_context_to_dict(context: EffectContext) -> Dictionary:
	return {
		"duel_manager": context.duel_manager,
		"player_data": context.player_data,
		"enemy_data": context.enemy_data,
		"duel_state": context.trigger_data.get("duel_state") if context.trigger_data else null,
		"cards_played_this_turn": context.trigger_data.get("cards_played_this_turn", 0) if context.trigger_data else 0,
		"hand_size": context.trigger_data.get("hand_size", 0) if context.trigger_data else 0,
		"card_instance": context.trigger_data.get("card_instance") if context.trigger_data else null
	}

## Apply a single effect with context for conditional evaluation
func _apply_single_effect_with_context(effect: Resource, duel_manager: DuelManager, card_instance: CardInstance, results: Dictionary, context: EffectContext, effect_index: int) -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	# Validate effect
	if not is_instance_valid(effect):
		result.error_message = "Effect %d is invalid" % effect_index
		return result
	
	# Handle both GameEffect (EffectContext) and legacy CardEffect (Dictionary) systems
	if effect is GameEffect:
		# GameEffect: Use EffectContext
		var can_apply: bool = true
		if effect.has_method("can_apply"):
			can_apply = effect.can_apply(context)
			
		if not can_apply:
			result.error_message = "Effect %d cannot be applied in current context" % effect_index
			return result
		
		# Apply GameEffect with EffectContext
		if effect.has_method("apply_effect"):
			var effect_result = effect.apply_effect(context)
			if effect_result and effect_result.has_method("get") and effect_result.get("success"):
				# Merge effect results into main results dictionary
				_merge_effect_result_into_results(effect_result, results)
				result.success = true
			else:
				result.error_message = "GameEffect failed to apply"
		else:
			result.error_message = "Effect %d has no applicable apply method" % effect_index
	
	else:
		# Legacy CardEffect: Convert EffectContext to Dictionary for compatibility
		var _legacy_context = _effect_context_to_dict(context)
		
		# Apply legacy CardEffect
		if effect.has_method("apply_effect_with_instance"):
			effect.apply_effect_with_instance(context.duel_manager, card_instance, results)
			result.success = true
		elif effect.has_method("apply_effect"):
			effect.apply_effect(context.duel_manager, card_instance.card_data, results)
			result.success = true
		else:
			result.error_message = "Legacy effect %d has no applicable apply method" % effect_index
	
	return result

## Helper to merge GameEffect results into legacy results format
func _merge_effect_result_into_results(effect_result: Resource, results: Dictionary) -> void:
	if not effect_result or not effect_result.has_method("get"):
		return
	
	var values_applied = effect_result.get("values_applied")
	if values_applied is Dictionary:
		for key in values_applied.keys():
			if key == "damage" and values_applied[key] > 0:
				results.damage += values_applied[key]
			elif key == "damage_hits" and values_applied[key] > 0:
				# Preserve multi-hit count for later application loop
				results.damage_hits = int(values_applied[key])
			elif key == "heal" and values_applied[key] > 0:
				results.heal += values_applied[key]
			elif key == "defense" and values_applied[key] > 0:
				results.defense += values_applied[key]
			elif key == "drawn" and values_applied[key] > 0:
				results.draw += values_applied[key]
			elif key == "ignores_defense" and values_applied[key]:
				results.ignores_defense = true
			# Add more mappings as needed
