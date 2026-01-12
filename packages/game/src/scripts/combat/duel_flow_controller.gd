## DuelFlowController
## Manages turn structure, phase transitions, and win/loss conditions.
## Follows Single Responsibility Principle - only handles duel flow, not card resolution or AI.
extends RefCounted
class_name DuelFlowController

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Signals for turn flow events
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal duel_ended(winner: String)

# Component dependencies
var duel_state: DuelState
var card_resolver: RefCounted # CardResolver - typed as RefCounted to avoid forward reference
var ai_controller: RefCounted # EnemyAIController - typed as RefCounted to avoid forward reference

func _init(state: DuelState) -> void:
	duel_state = state
	if not duel_state:
		GLog.error("DuelFlowController: initialized with null DuelState")
	else:
		# Connect to state changes to monitor win/loss conditions
		duel_state.add_change_listener(_on_duel_state_changed)

# Turn management methods
func start_duel(player_deck: DeckData, enemy_data: EnemyState) -> void:
	"""Initialize duel setup sequence, draw hands, start first turn"""
	GLog.info("DuelFlowController: starting new duel...")
	
	if not duel_state:
		GLog.error("DuelFlowController: Cannot start duel - no DuelState")
		return
	
	# Debug enemy health before assignment
	if enemy_data and enemy_data.stats:
		GLog.debug("DuelFlowController: Enemy loaded with HP: %d/%d" % [enemy_data.stats.current_health, enemy_data.stats.max_health])
	
	duel_state.enemy_data = enemy_data
	
	# Debug enemy health after assignment
	if duel_state.enemy_data and duel_state.enemy_data.stats:
		GLog.debug("DuelFlowController: Enemy assigned to duel_state with HP: %d/%d" % [duel_state.enemy_data.stats.current_health, duel_state.enemy_data.stats.max_health])
	
	# Batch notifications during duel setup to avoid UI flicker/resets
	if duel_state and duel_state.has_method("begin_batch_changes"):
		duel_state.begin_batch_changes()

	# Clear all card piles
	duel_state.deck.clear()
	duel_state.discard_pile.clear()
	duel_state.hand.clear()
	duel_state.removed_pile.clear()
	
	# Load cards from DeckData and convert to CardInstance array
	for card_path in player_deck.card_paths:
		var card_data = load(card_path) as CardData
		if card_data:
			duel_state.deck.add_card_data(card_data)
		else:
			GLog.error("DuelFlowController: Failed to load card from DeckData: %s" % card_path)
	
	duel_state.deck.shuffle()
	
	duel_state.start_duel()
	
	# Load enemy deck
	_load_enemy_deck(enemy_data)
	
	# Draw initial enemy hand
	var enemy_initial_draw = enemy_data.draw_cards(5)
	GLog.info("DuelFlowController: Drew initial enemy hand: %d cards" % enemy_initial_draw.size())
	
	# Draw initial player hand
	_draw_initial_hand()
	
	# End batch and emit a consolidated update once everything is ready
	if duel_state and duel_state.has_method("end_batch_changes"):
		duel_state.end_batch_changes()
	
	# Start first turn
	start_player_turn()

func start_duel_with_config(config: DuelConfig) -> void:
	"""Initialize duel from a DuelConfig object (runtime data)"""
	GLog.info("DuelFlowController: Starting duel from config...")
	
	if not duel_state:
		GLog.error("DuelFlowController: Cannot start duel - no DuelState")
		return
		
	# 1. Assign enemy data (triggers setter we added earlier)
	duel_state.enemy_data = config.enemy_data
	
	# 2. Batch notifications
	if duel_state.has_method("begin_batch_changes"):
		duel_state.begin_batch_changes()

	# 3. Clear all card piles
	duel_state.deck.clear()
	duel_state.discard_pile.clear()
	duel_state.hand.clear()
	duel_state.removed_pile.clear()
	duel_state.battlefield.clear()
	
	# 4. Load cards from Config directly (already CardData objects)
	for card in config.player_deck:
		if card:
			duel_state.deck.add_card_data(card)
	
	duel_state.deck.shuffle()
	
	# 5. Initialize duel state (turns, active flag, etc)
	duel_state.start_duel()
	
	# 6. Load enemy deck (delegated to enemy state)
	if duel_state.enemy_data is EnemyState:
		_load_enemy_deck(duel_state.enemy_data)
		
		# Draw initial enemy hand
		var enemy_initial_draw = duel_state.enemy_data.draw_cards(5)
		GLog.info("DuelFlowController: Drew initial enemy hand: %d cards" % enemy_initial_draw.size())
	
	# 7. Draw initial player hand
	_draw_initial_hand()
	
	# 8. End batch
	if duel_state.has_method("end_batch_changes"):
		duel_state.end_batch_changes()
	
	# 9. Start first turn
	start_player_turn()

func start_player_turn() -> void:
	"""Increment turn count, draw cards, emit signal"""
	GLog.info("DuelFlowController: Starting player turn %d" % (duel_state.player_turn_count + 1))

	duel_state.start_player_turn()

	# Process status effects that trigger at turn start (Poison, Dread, Recovery, Surge)
	if duel_state.player_data and duel_state.player_data.status_effects:
		var effects := duel_state.player_data.status_effects.process_turn_start()
		for effect in effects:
			_apply_status_effect_result(duel_state.player_data, effect)

	# Draw cards for turn (except first turn which already drew initial hand)
	if duel_state.player_turn_count > 1:
		var base_draw := 1 # Standard card draw per turn
		var draw_mod := 0

		# Apply Clarity/Confusion draw modifiers
		if duel_state.player_data and duel_state.player_data.status_effects:
			draw_mod = duel_state.player_data.status_effects.get_draw_modifier()

		var actual_draw := maxi(1, base_draw + draw_mod) # Minimum 1 draw
		var drawn := duel_state.draw_cards(actual_draw)
		if drawn.size() > 0:
			GLog.debug("DuelFlowController: Drew %d card(s) for turn (base: %d, modifier: %+d)" % [drawn.size(), base_draw, draw_mod])

	turn_started.emit(true)

func end_player_turn() -> void:
	"""Process end-of-turn effects, emit signal"""
	GLog.debug("DuelFlowController: Ending player turn")

	# Process status effects that trigger at turn end (Burn, Resolve)
	if duel_state.player_data and duel_state.player_data.status_effects:
		var effects := duel_state.player_data.status_effects.process_turn_end()
		for effect in effects:
			_apply_status_effect_result(duel_state.player_data, effect)

		# Decay effects that decay at turn end
		duel_state.player_data.status_effects.decay_effects("per_turn_end")

	# Process player end-of-turn effects (like delayed damage)
	if duel_state.player_data:
		duel_state.player_data.end_turn()

	duel_state.end_player_turn()
	turn_ended.emit(true)

	# Check for win/loss conditions
	var winner = check_win_loss_conditions()
	if winner != "":
		duel_ended.emit(winner)
		return

	# Check if duel is over before starting enemy turn
	if not is_duel_over():
		# Brief pause before transitioning to enemy turn
		await Engine.get_main_loop().create_timer(GameConstants.TIMING_VALUES["turn_transition_delay"]).timeout
		start_enemy_turn()

func start_enemy_turn() -> void:
	"""Increment turn count, emit signal"""
	GLog.info("DuelFlowController: Starting enemy turn %d" % (duel_state.enemy_turn_count + 1))

	duel_state.start_enemy_turn()

	# Process status effects that trigger at turn start (Poison, Dread, Recovery, Surge)
	if duel_state.enemy_data and duel_state.enemy_data.status_effects:
		var effects := duel_state.enemy_data.status_effects.process_turn_start()
		for effect in effects:
			_apply_status_effect_result(duel_state.enemy_data, effect)

	turn_started.emit(false)

	# Note: Enemy AI execution will be handled by EnemyAIController


func end_enemy_turn() -> void:
	"""Emit signal, check for next turn"""
	GLog.debug("DuelFlowController: Ending enemy turn")

	# Process status effects that trigger at turn end (Burn, Resolve)
	if duel_state.enemy_data and duel_state.enemy_data.status_effects:
		var effects := duel_state.enemy_data.status_effects.process_turn_end()
		for effect in effects:
			_apply_status_effect_result(duel_state.enemy_data, effect)

		# Decay effects that decay at turn end
		duel_state.enemy_data.status_effects.decay_effects("per_turn_end")

	duel_state.end_enemy_turn()
	turn_ended.emit(false)

	# Check for win/loss conditions
	var winner = check_win_loss_conditions()
	if winner != "":
		duel_ended.emit(winner)
		return

	# Check if duel is over before starting next player turn
	if not is_duel_over():
		# Brief pause before transitioning to player turn
		await Engine.get_main_loop().create_timer(GameConstants.TIMING_VALUES["turn_transition_delay"]).timeout
		start_player_turn()

# Helper methods

func _apply_status_effect_result(entity: Resource, effect: Dictionary) -> void:
	"""Apply the result of a status effect trigger to an entity"""
	var effect_type: String = effect.get("type", "")
	var value: int = effect.get("value", 0)
	var effect_id: String = effect.get("effect_id", "")
	var bypasses_defense: bool = effect.get("bypasses_defense", false)

	match effect_type:
		"damage":
			if bypasses_defense and entity is EnemyState:
				entity.take_damage(value, true)
			else:
				entity.take_damage(value)
			GLog.debug("DuelFlowController: %s dealt %d damage from %s" % [_get_entity_name(entity), value, effect_id])
		"heal":
			entity.heal(value)
			GLog.debug("DuelFlowController: %s healed %d from %s" % [_get_entity_name(entity), value, effect_id])
		"sanity_damage":
			if entity.stats:
				entity.stats.lose_sanity(value)
			GLog.debug("DuelFlowController: %s took %d sanity damage from %s" % [_get_entity_name(entity), value, effect_id])
		"sanity_heal":
			if entity.stats:
				entity.stats.restore_sanity(value)
			GLog.debug("DuelFlowController: %s restored %d sanity from %s" % [_get_entity_name(entity), value, effect_id])
		"energy_gain":
			if entity.stats:
				entity.stats.restore_energy(value)
			GLog.debug("DuelFlowController: %s gained %d energy from %s" % [_get_entity_name(entity), value, effect_id])

	# Emit status triggered event
	EventBus.status_triggered.emit(entity, effect_id, float(value))


func _get_entity_name(entity: Resource) -> String:
	"""Get display name for an entity"""
	if entity is EnemyState and entity.enemy_name:
		return entity.enemy_name
	if entity is PlayerData:
		return "Player"
	return "Entity"


func _draw_initial_hand() -> void:
	"""Draw initial hand of cards"""
	var initial_hand_size = 5 # Standard initial hand size
	var drawn = duel_state.draw_cards(initial_hand_size)
	GLog.info("DuelFlowController: Drew initial hand of %d cards" % drawn.size())

func _load_enemy_deck(enemy: EnemyState) -> void:
	"""Load the enemy's deck from configured card paths"""
	GLog.info("DuelFlowController: Loading enemy deck for %s" % enemy.enemy_name)
	
	# Clear existing piles
	enemy.enemy_hand.clear()
	enemy.enemy_discard.clear()
	
	# Initialize deck from DeckData resource or legacy paths
	enemy.initialize_deck_from_data()
	
	# Shuffle the deck
	enemy.enemy_deck.shuffle()
	GLog.info("DuelFlowController: Enemy deck loaded: %d cards" % enemy.enemy_deck.size())

# Win/loss condition checking
func check_win_loss_conditions() -> String:
	"""Evaluate health and sanity to determine winner"""
	if not duel_state:
		return ""
	
	# Check if player died (health <= 0)
	if duel_state.player_data and duel_state.player_data.is_dead():
		GLog.info("DuelFlowController: Player died - enemy wins")
		return "enemy"
	
	# Check if player went insane (sanity <= 0)
	if duel_state.player_data and duel_state.player_data.is_insane():
		GLog.info("DuelFlowController: Player went insane - enemy wins")
		return "enemy"
	
	# Check if enemy died (health <= 0)
	if duel_state.enemy_data and duel_state.enemy_data.is_dead():
		GLog.info("DuelFlowController: Enemy died - player wins")
		return "player"
	
	# No win/loss condition met
	return ""

func is_duel_over() -> bool:
	"""Return boolean based on win/loss conditions"""
	if not duel_state:
		return false
	
	# Use DuelState's built-in check
	return duel_state.is_duel_over()

func _on_duel_state_changed(_change_type: String, _data: Dictionary) -> void:
	"""Handle duel state changes to check for immediate win/loss"""
	# Ignore state changes if the duel is not active (e.g. during setup)
	if not duel_state or not duel_state.duel_active:
		return

	# Check for win/loss conditions immediately on any state change
	# This ensures we catch death events right away instead of waiting for end of turn
	var winner = check_win_loss_conditions()
	if winner != "":
		GLog.info("DuelFlowController: Immediate win/loss detected: %s" % winner)
		duel_ended.emit(winner)