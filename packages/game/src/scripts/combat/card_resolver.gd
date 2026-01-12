## CardResolver
## Handles card validation, cost payment, and effect resolution.
## NOW REFACTORED: Handles effect processing loop directly, removing EffectProcessor.
extends RefCounted
class_name CardResolver

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Signals for card resolution events
signal card_played(card_instance: CardInstance)
signal enemy_card_played(card: CardData)

# Component dependencies
var duel_state: DuelState
var duel_manager: DuelManager

func _init(state: DuelState, manager: DuelManager = null) -> void:
	duel_state = state
	duel_manager = manager
	
	if not duel_state:
		GLog.error("CardResolver: initialized with null DuelState")
	
	GLog.debug("CardResolver: initialized")

## Card Validation Methods

## Card Validation Methods

func can_play_card(card_data: CardData) -> bool:
	"""Check if a card can be played based on energy, sanity, and resource costs"""
	if not duel_state or not duel_state.can_play_cards():
		GLog.debug("CardResolver: Cannot play cards - duel state invalid or cards disabled")
		return false

	if not card_data:
		GLog.error("CardResolver: can_play_card called with null card_data")
		return false

	var player = duel_state.player_data
	if not player:
		GLog.error("CardResolver: can_play_card called with invalid player data")
		return false

	# Check Disarmed status for Attack cards
	if card_data.card_type == GameConstants.CardType.ATTACK:
		if player.status_effects and not player.status_effects.can_play_attack():
			GLog.debug("CardResolver: Cannot play Attack cards while Disarmed")
			return false

	# Check Unified Costs (Energy, Sanity, Resource, Custom)
	for cost in card_data.get_costs():
		if not cost.can_pay(player):
			GLog.debug("CardResolver: Cannot afford cost: %s" % cost.get_description())
			return false
	
	# Check Legacy Effect Costs (Faith and other custom resources defined in effects)
	# TODO: Migrate these to ResourceCost and remove this block
	var resource_costs = _get_resource_costs(card_data)
	for resource_name in resource_costs:
		var cost = resource_costs[resource_name]
		var res_type = player._string_to_resource_type(resource_name)
		if res_type != GameEnums.CustomResourceType.NONE:
			if not player.can_afford_resource(res_type, cost):
				GLog.debug("CardResolver: Cannot afford (Effect) %s cost: %d (have: %d)" % [
					resource_name, cost, player.get_resource(res_type)
				])
				return false
	
	# Check additional custom resource costs (Legacy property support if any slipped through)
	var custom_costs = _get_custom_resource_costs(card_data)
	for resource_name in custom_costs:
		var cost = custom_costs[resource_name]
		var res_type = player._string_to_resource_type(resource_name)
		if res_type != GameEnums.CustomResourceType.NONE:
			if player.get_resource(res_type) < cost:
				GLog.debug("CardResolver: Cannot afford custom resource %s cost: %d" % [
					resource_name, cost
				])
				return false
	
	return true

func _get_resource_costs(card_data: CardData) -> Dictionary:
	"""Extract Faith and custom resource costs from card effects (negative amounts are costs)"""
	if not card_data or not card_data.effects:
		return {}
	
	var costs = {}
	
	for effect in card_data.effects:
		# Handle ResourceHandler for custom resources
		if effect.has_method("get_resource_type"): # Duck typing check
			# Assuming ResourceHandler has resource_type string and amount
			# Accessing properties dynamically because class might not be globally named ResourceHandler in all contexts
			var type = effect.get("resource_type")
			var amount = effect.get("amount")
			
			if type and amount != null and type not in ["gold", "energy", "sanity"]:
				if amount < 0:
					var current_cost = costs.get(type, 0)
					costs[type] = current_cost + (-amount)
	
	return costs

func _get_custom_resource_costs(card_data: CardData) -> Dictionary:
	"""Extract custom resource costs from legacy property if used (Backwards Compat)"""
	# Since we moved unique_resource_costs to CardCost in get_costs(), this might be redundant
	# unless we are looking specifically for effect-based ones again?
	# Original code looked at effects again. Let's keep strict to CardData structure.
	if card_data.unique_resource_costs.size() > 0:
		# These are now handled by get_costs() fallback, so we should ignore them here to avoid double counting
		# IF get_costs() is used.
		return {}
		
	return {}

## Cost Payment Methods

func _pay_all_costs(source: Object, card_data: CardData) -> void:
	"""Pay all costs for a card (energy, sanity, resources)"""
	if not source or not card_data:
		GLog.error("CardResolver: _pay_all_costs called with null parameters")
		return
	
	# Pay Unified Costs
	for cost in card_data.get_costs():
		cost.pay(source)
		# GLog.debug("CardResolver: Paid cost: %s" % cost.get_description())
	
	# Pay Legacy Effect Costs
	var resource_costs = _get_resource_costs(card_data)
	for resource_name in resource_costs:
		var pay_amount = resource_costs[resource_name]
		if pay_amount > 0:
			var res_type = source._string_to_resource_type(resource_name)
			if res_type != GameEnums.CustomResourceType.NONE:
				if source.has_method("spend_resource"):
					source.spend_resource(res_type, pay_amount)
					GLog.debug("CardResolver: Paid (Effect) %d %s" % [pay_amount, resource_name])


## Card Resolution Methods

func play_player_card(card_instance: CardInstance) -> void:
	"""Validate, pay costs, stage, and resolve a player card"""
	if not can_play_card(card_instance.card_data):
		GLog.warn("CardResolver: Cannot play card: %s" % card_instance.get_card_name())
		return

	GLog.info("CardResolver: Playing card: %s" % card_instance.get_card_name())

	var player = duel_state.player_data

	# Capture timing context BEFORE incrementing counter
	var cards_played_before = player.cards_played_this_turn
	var hand_size_before = duel_state.hand.size() - 1 # -1 because we're about to play this card

	# Pay all costs upfront to ensure consistent state
	_pay_all_costs(player, card_instance.card_data)

	# Increment counter for this turn
	player.cards_played_this_turn += 1
	player.apply_card_cost_reductions()

	# Move card to battlefield temporarily for visual feedback
	duel_state.play_card(card_instance)

	# Emit event for UI to show card on battlefield
	card_played.emit(card_instance)

	# Track this card for enemy memory
	_track_player_card_for_enemy_memory(card_instance.card_data)

	# Wait for card to be displayed on battlefield before resolving
	await Engine.get_main_loop().create_timer(GameConstants.TIMING_VALUES["card_stage_delay"]).timeout

	# Resolve the card with timing context
	resolve_card(card_instance, true, cards_played_before, hand_size_before)

func play_enemy_card(enemy: EnemyState, card: CardData) -> void:
	"""Spend energy, stage, and resolve an enemy card with proper timing"""
	GLog.info("CardResolver: Enemy plays: %s (Cost: %d)" % [card.card_name, card.energy_cost])
	
	# Pay all costs upfront (energy, resources, etc.)
	_pay_all_costs(enemy, card)
	
	# Move card from enemy hand to battlefield temporarily
	var staged_instance: CardInstance = null
	if enemy.enemy_hand.remove_card_data(card):
		duel_state.battlefield.add_card_data(card)
		# Retrieve the actual instance we just added so we can resolve/remove the same one
		staged_instance = duel_state.battlefield.find_instance_by_card_data(card)
		GLog.debug("CardResolver: Enemy card '%s' staged on battlefield (instance acquired: %s)" % [card.card_name, str(staged_instance)])
	
	# Emit event for UI to show card
	enemy_card_played.emit(card)
	
	# Wait for card to be displayed before resolving
	await Engine.get_main_loop().create_timer(GameConstants.TIMING_VALUES["card_stage_delay"]).timeout
	
	# Resolve the card using the staged instance so battlefield removal works
	if staged_instance:
		resolve_card(staged_instance, false)
	else:
		# Fallback: if for some reason we couldn't acquire the staged instance, resolve with a temp
		var temp_instance := CardInstance.new(card)
		GLog.warn("CardResolver: Could not find staged instance for enemy card '%s'; resolving with temp instance" % card.card_name)
		resolve_card(temp_instance, false)

func resolve_card(card_instance: CardInstance, is_player: bool, cards_played_before: int = 0, hand_size_before: int = 0) -> void:
	"""Apply effects and route card to destination pile"""
	if not duel_state or not card_instance:
		GLog.error("CardResolver: resolve_card called with invalid parameters")
		return
	
	GLog.info("CardResolver: Resolving card: %s" % card_instance.get_card_name())
	
	# Create Context at the start of resolution
	var context: HandlerContext = card_instance.create_context(duel_manager)
	
	# For player cards, populate timing debug info if needed
	if is_player:
		# We can add strictly relevant runtime data if needed, but Context handles the heavy lifting
		if context.trigger_data == null:
			context.trigger_data = {}
		context.trigger_data["cards_played_before"] = cards_played_before
		context.trigger_data["cards_played_this_turn"] = cards_played_before
		context.trigger_data["hand_size_before"] = hand_size_before

	# Execute card effects
	var results: Array[HandlerResult] = _process_card_effects(card_instance, context)
	
	# Apply Gambling Modifiers (Post-Processing)
	if is_player:
		_apply_gambling_modifiers_to_results(results)
	
	# Apply effect results to appropriate targets
	if is_player:
		apply_effect_results(results, duel_state.player_data, duel_state.enemy_data)
		
		# Remove from battlefield and move to player's final destination
		duel_state.battlefield.remove_card(card_instance)
		match card_instance.get_card_handling():
			"Standard", "Equipped", "Flash":
				duel_state.discard_pile.add_card(card_instance)
			"Hold":
				duel_state.hand.add_card(card_instance)
			"Oneshot", "Exhaust":
				duel_state.removed_pile.add_card(card_instance)
				EventBus.card_exhausted.emit(card_instance)
			_:
				duel_state.discard_pile.add_card(card_instance)
		
		GLog.debug("CardResolver: Resolved player card: %s" % card_instance.get_card_name())
	else:
		# Enemy card
		var enemy = duel_state.enemy_data as EnemyState
		apply_effect_results(results, enemy, duel_state.player_data)
		
		# Remove from battlefield and move enemy card to discard
		duel_state.battlefield.remove_card(card_instance)
		if enemy:
			enemy.enemy_discard.add_card_data(card_instance.card_data)
		
		GLog.debug("CardResolver: Resolved enemy card: %s" % card_instance.get_card_name())

# NEW: Internal effect processing loop
func _process_card_effects(card_instance: CardInstance, context: HandlerContext) -> Array[HandlerResult]:
	var results: Array[HandlerResult] = []
	
	if not card_instance.card_data or not card_instance.card_data.effects:
		return results
		
	for effect in card_instance.card_data.effects:
		if not effect or not effect is HandlerBase:
			continue
			
		# Check activation condition
		if not effect.can_apply(context):
			continue
			
		# Apply effect
		var result = effect.apply_effect(context)
		if result:
			results.append(result)
			
	return results

# NEW: Gambling Logic Migration
func _apply_gambling_modifiers_to_results(effect_results: Array[HandlerResult]) -> void:
	if not duel_state or not duel_state.player_data:
		return
	
	var player_data = duel_state.player_data
	
	if not player_data.has_method("check_and_apply_gambling"):
		return
	
	# Check if gambling is active
	var gambling_result = player_data.check_and_apply_gambling()
	
	if not gambling_result is Dictionary or not gambling_result.get("active", false):
		return
	
	var multiplier = gambling_result.get("multiplier", 1.0)
	
	GLog.debug("CardResolver: Gambling active! Multiplier: %.1fx" % multiplier)
	
	# Query for success chance modifiers
	var context = {
		"success_chance": 0.5,
		"player_data": player_data
	}
	# Safe signal emission
	if EventBus and EventBus.has_signal("gambling_modifier_query"):
		EventBus.gambling_modifier_query.emit(player_data, context)
	
	var success_chance = context.get("success_chance", 0.5)
	
	# Roll for success
	if SeedManager.get_combat_random_float() < success_chance:
		# SUCCESS: Multiply effects
		var multiplied_fields = ["damage", "defense", "heal"]
		for result in effect_results:
			if not result.success:
				continue
			
			for field in multiplied_fields:
				if result.values_applied.has(field) and result.values_applied[field] is int:
					result.values_applied[field] = int(result.values_applied[field] * multiplier)
		
		GLog.debug("CardResolver: Gambling SUCCESS! Effects multiplied by %.1fx" % multiplier)
	else:
		# FAILURE: Zero out effects
		for result in effect_results:
			if not result.success:
				continue
			
			# Zero out damage, defense, and heal effects
			if result.values_applied.has("damage"):
				result.values_applied["damage"] = 0
			if result.values_applied.has("defense"):
				result.values_applied["defense"] = 0
			if result.values_applied.has("heal"):
				result.values_applied["heal"] = 0
		
		GLog.debug("CardResolver: Gambling FAILED! All effects negated")

func apply_effect_results(effect_results: Array[HandlerResult], source, target) -> void:
	"""Map effect results to appropriate state changes"""
	for result in effect_results:
		if not result.success:
			continue
		_apply_single_result(result.values_applied, source, target)

## Helper Methods

func _track_player_card_for_enemy_memory(card: CardData) -> void:
	"""Track cards played by player for enemy AI adaptation"""
	var enemy = duel_state.enemy_data as EnemyState
	if enemy:
		enemy.add_to_player_memory(card.card_name)

func _apply_single_result(values: Dictionary, source: RefCounted, target: RefCounted) -> void:
	"""Apply a single result's values to the appropriate game state"""
	# Damage goes to target with status modifiers
	if values.has("damage") and values.damage > 0:
		var ignore_defense = values.get("ignores_defense", false)
		var hits = int(values.get("damage_hits", 1))

		for i in range(max(1, hits)):
			var final_damage := int(values.damage)

			# Apply source status modifiers (Grit bonus, Weak penalty)
			if source and "status_effects" in source and source.status_effects:
				# Grit: +1 damage per stack (flat bonus)
				final_damage += source.status_effects.get_damage_bonus()
				# Weak: -25% damage (multiplicative)
				final_damage = int(final_damage * source.status_effects.get_damage_multiplier())

			# Apply target status modifiers (Wounded)
			if target and "status_effects" in target and target.status_effects:
				# Wounded: +50% damage taken (multiplicative)
				final_damage = int(final_damage * target.status_effects.get_damage_taken_multiplier())

			final_damage = maxi(0, final_damage)

			# Apply damage
			var actual_damage := 0
			if target is EnemyState:
				actual_damage = target.take_damage(final_damage, ignore_defense)
			else:
				actual_damage = target.take_damage(final_damage)

			# Post-damage status effects: Thorns reflection
			if actual_damage > 0 and target and "status_effects" in target and target.status_effects:
				var reflect := target.status_effects.get_reflection_damage(actual_damage)
				if reflect > 0 and source:
					source.take_damage(reflect)
					GLog.debug("CardResolver: Thorns reflected %d damage back to attacker" % reflect)

			# Post-damage status effects: Drain lifesteal
			if actual_damage > 0 and source and "status_effects" in source and source.status_effects:
				var lifesteal := source.status_effects.get_lifesteal_amount(actual_damage)
				if lifesteal > 0:
					source.heal(lifesteal)
					GLog.debug("CardResolver: Drain healed %d from damage dealt" % lifesteal)

	# Defense goes to source with status modifiers
	if values.has("defense") and values.defense > 0:
		var final_defense := int(values.defense)

		if source and "status_effects" in source and source.status_effects:
			# Guard: +1 defense per stack (flat bonus)
			final_defense += source.status_effects.get_defense_bonus()
			# Rattled: -25% defense (multiplicative)
			final_defense = int(final_defense * source.status_effects.get_defense_multiplier())

		final_defense = maxi(0, final_defense)
		source.gain_defense(final_defense)
	
	# Heal goes to source
	if values.has("heal") and values.heal > 0:
		source.heal(values.heal)
	
	# Draw cards (source's deck)
	if values.has("drawn") and values.drawn > 0:
		duel_state.draw_cards(values.drawn)
	
	# Custom resources (Faith, Ammo, Brew, etc.) go to source
	if values.has("custom_resources"):
		for resource_name in values.custom_resources:
			var amount = values.custom_resources[resource_name]
			var res_type = source._string_to_resource_type(resource_name)
			if res_type != GameEnums.CustomResourceType.NONE:
				source.modify_resource(res_type, amount)
			else:
				GLog.warn("CardResolver: Unknown custom resource type: %s" % resource_name)
	
	# Gold goes to source
	if values.has("gold") and values.gold != 0:
		if source.stats:
			source.stats.gain_gold(values.gold)
	
	# Status effects go to target
	if values.has("stun_enemy") and values.stun_enemy > 0:
		target.apply_stun(values.stun_enemy)
	
	# Delayed effects
	if values.has("delayed_damage") and values.delayed_damage > 0:
		source.delayed_damage += values.delayed_damage
	
	# Delayed defense
	if values.has("delayed_defense") and values.delayed_defense > 0:
		source.delayed_defense += values.delayed_defense
	
	# Energy restoration
	if values.has("energy") and values.energy != 0:
		source.restore_energy(values.energy)
	
	# Sanity restoration
	if values.has("sanity") and values.sanity > 0:
		source.restore_sanity(values.sanity)
	
	# Sanity damage (enemy attacks targeting mental state)
	if values.has("sanity_damage") and values.sanity_damage > 0:
		if target and target.stats:
			target.stats.lose_sanity(values.sanity_damage)
			GLog.debug("CardResolver: Applied %d sanity damage to target" % values.sanity_damage)
	
	# Card manipulation
	if values.has("discard_random") and values.discard_random > 0:
		duel_state.discard_random_cards(values.discard_random)
	
	if values.has("exhaust_random") and values.exhaust_random > 0:
		duel_state.exhaust_random_cards(values.exhaust_random)
	
	# Apply new status effect system
	if values.has("apply_status"):
		var status_data: Dictionary = values.apply_status
		var effect_id: String = status_data.get("effect_id", "")
		var stacks: int = status_data.get("stacks", 1)
		var target_type: String = status_data.get("target_type", "enemy")

		if effect_id and not effect_id.is_empty():
			var effect_data := _load_status_effect(effect_id)
			if effect_data:
				var status_target = source if target_type == "self" else target
				if status_target and "status_effects" in status_target and status_target.status_effects:
					status_target.status_effects.apply_status(effect_data, stacks, source)
					GLog.debug("CardResolver: Applied %d %s to %s" % [stacks, effect_id, target_type])
			else:
				GLog.warn("CardResolver: Could not load status effect: %s" % effect_id)

	# Log warnings for unknown keys
	for key in values.keys():
		if key not in ["damage", "defense", "heal", "drawn", "custom_resources", "gold",
					   "stun_enemy", "delayed_damage", "delayed_defense", "energy", "sanity",
					   "sanity_damage", "discard_random", "exhaust_random", "ignores_defense",
					   "damage_hits", "apply_status", "enemy_debuff", "status"]:
			GLog.warn("CardResolver: Unknown effect key: %s" % key)


func _load_status_effect(effect_id: String) -> StatusEffectData:
	"""Load a status effect resource by ID"""
	var search_paths := [
		"res://data/status_effects/%s.tres" % effect_id,
		"res://data/status_effects/debuffs/%s.tres" % effect_id,
		"res://data/status_effects/buffs/%s.tres" % effect_id,
	]

	for path in search_paths:
		if ResourceLoader.exists(path):
			return load(path) as StatusEffectData

	return null
