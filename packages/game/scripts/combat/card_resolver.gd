## CardResolver
## Handles card validation, cost payment, and effect resolution.
## NOW REFACTORED: Handles effect processing loop directly, removing EffectProcessor.
extends RefCounted
class_name CardResolver

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Timing constants for card resolution
const CARD_STAGE_DELAY: float = 0.5 # Time card sits on battlefield before resolving
const ENEMY_CARD_PLAY_DELAY: float = 1.5 # Time between enemy card plays

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
	
	# Check energy cost (with modifiers)
	var actual_cost = player.get_actual_energy_cost(card_data.energy_cost, card_data.card_type)
	if not player.can_afford_card(actual_cost, card_data.sanity_cost):
		GLog.debug("CardResolver: Cannot afford card: %s (energy: %d/%d, sanity: %d/%d)" % [
			card_data.card_name, actual_cost, player.stats.current_energy,
			card_data.sanity_cost, player.stats.current_sanity
		])
		return false
	
	# Check resource costs (Faith and other custom resources)
	var resource_costs = _get_resource_costs(card_data)
	for resource_name in resource_costs:
		var cost = resource_costs[resource_name]
		if not player.can_afford_resource(resource_name, cost):
			GLog.debug("CardResolver: Cannot afford %s cost: %d (have: %d)" % [
				resource_name, cost, player.get_resource(resource_name)
			])
			return false
	
	# Check additional custom resource costs
	var custom_costs = _get_custom_resource_costs(card_data)
	for resource_name in custom_costs:
		var cost = custom_costs[resource_name]
		if player.get_custom_resource(resource_name) < cost:
			GLog.debug("CardResolver: Cannot afford custom resource %s cost: %d (have: %d)" % [
				resource_name, cost, player.get_custom_resource(resource_name)
			])
			return false
	
	return true

func _get_resource_costs(card_data: CardData) -> Dictionary:
	"""Extract Faith and custom resource costs from card effects (negative amounts are costs)"""
	if not card_data or not card_data.effects:
		return {}
	
	var costs = {}
	
	for effect in card_data.effects:
		# Handle ResourceHandler for custom resources (including Faith)
		if effect is ResourceHandler:
			var res_effect = effect as ResourceHandler
			if res_effect.resource_type not in ["gold", "energy", "sanity"]:
				if res_effect.amount < 0:
					var current_cost = costs.get(res_effect.resource_type, 0)
					costs[res_effect.resource_type] = current_cost + (-res_effect.amount)
	
	return costs

func _get_custom_resource_costs(card_data: CardData) -> Dictionary:
	"""Extract custom resource costs from card effects (negative amounts are costs)"""
	if not card_data or not card_data.effects:
		return {}
	
	var costs = {}
	
	for effect in card_data.effects:
		if effect is ResourceHandler:
			var res_effect = effect as ResourceHandler
			# Check if it's a custom resource (not standard)
			if res_effect.resource_type not in ["gold", "energy", "sanity"]:
				# Both negative and positive amounts; negative = cost, positive = gain
				if res_effect.amount < 0: # Only costs (negative amounts)
					var current_cost = costs.get(res_effect.resource_type, 0)
					costs[res_effect.resource_type] = current_cost + (-res_effect.amount)
	
	return costs

## Cost Payment Methods

func _pay_all_costs(player, card_instance: CardInstance) -> void:
	"""Pay all costs for a card (energy, sanity, resources) with modifiers applied"""
	if not player or not card_instance:
		GLog.error("CardResolver: _pay_all_costs called with null parameters")
		return
	
	var card_data = card_instance.card_data
	
	# Calculate and pay energy cost with modifiers
	var actual_cost = player.get_actual_energy_cost(card_data.energy_cost, card_data.card_type)
	player.pay_energy(actual_cost)
	GLog.debug("CardResolver: Paid %d energy for %s (base: %d)" % [actual_cost, card_data.card_name, card_data.energy_cost])
	
	# Pay sanity cost
	if card_data.sanity_cost > 0:
		player.pay_sanity(card_data.sanity_cost)
		GLog.debug("CardResolver: Paid %d sanity for %s" % [card_data.sanity_cost, card_data.card_name])
	
	# Pay resource costs (Faith and other resources from effects)
	var resource_costs = _get_resource_costs(card_data)
	for resource_name in resource_costs:
		var cost = resource_costs[resource_name]
		if cost > 0:
			player.spend_resource(resource_name, cost)
			GLog.debug("CardResolver: Paid %d %s cost for %s (current: %d)" % [
				cost, resource_name, card_data.card_name, player.get_resource(resource_name)
			])
	
	# Pay custom resource costs
	var custom_costs = _get_custom_resource_costs(card_data)
	for resource_name in custom_costs:
		var cost = custom_costs[resource_name]
		if cost > 0:
			player.modify_custom_resource(resource_name, -cost)
			GLog.debug("CardResolver: Paid %d %s cost for %s (current: %d)" % [
				cost, resource_name, card_data.card_name, player.get_custom_resource(resource_name)
			])

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
	_pay_all_costs(player, card_instance)
	
	# Increment counter for this turn
	player.cards_played_this_turn += 1
	player.apply_card_cost_reductions()
	
	# Move card to battlefield temporarily for visual feedback
	duel_state.play_card(card_instance)
	
	# Emit event for UI to show card on battlefield
	card_played.emit(card_instance)
	
	# Track this card for enemy memory
	_track_player_card_for_enemy_memory(card_instance.card_data)
	
	# Note: Timing delay will be handled by the caller (DuelManager)
	# Immediately resolve the card with timing context
	resolve_card(card_instance, true, cards_played_before, hand_size_before)

func play_enemy_card(enemy: EnemyState, card: CardData) -> void:
	"""Spend energy, stage, and resolve an enemy card with proper timing"""
	GLog.info("CardResolver: Enemy plays: %s (Cost: %d)" % [card.card_name, card.energy_cost])
	
	# Spend energy upfront
	if enemy.stats:
		enemy.stats.current_energy -= card.energy_cost
	
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
	await Engine.get_main_loop().create_timer(CARD_STAGE_DELAY).timeout
	
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
	# Damage goes to target
	if values.has("damage") and values.damage > 0:
		var ignore_defense = values.get("ignores_defense", false)
		var hits = int(values.get("damage_hits", 1))
		for i in range(max(1, hits)):
			# EnemyState supports ignore_defense parameter, PlayerData doesn't
			if target is EnemyState:
				target.take_damage(values.damage, ignore_defense)
			else:
				target.take_damage(values.damage)
	
	# Defense goes to source
	if values.has("defense") and values.defense > 0:
		source.gain_defense(values.defense)
	
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
			source.modify_resource(resource_name, amount)
	
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
	
	# Card manipulation
	if values.has("discard_random") and values.discard_random > 0:
		duel_state.discard_random_cards(values.discard_random)
	
	if values.has("exhaust_random") and values.exhaust_random > 0:
		duel_state.exhaust_random_cards(values.exhaust_random)
	
	# Log warnings for unknown keys
	for key in values.keys():
		if key not in ["damage", "defense", "heal", "drawn", "custom_resources", "gold",
					   "stun_enemy", "delayed_damage", "delayed_defense", "energy", "sanity",
					   "discard_random", "exhaust_random", "ignores_defense", "damage_hits"]:
			GLog.warn("CardResolver: Unknown effect key: %s" % key)
