extends Node
class_name DuelManager

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

@export_group("Duel Configuration")
@export var duel_state: DuelState
@export_range(3, 10) var initial_hand_size: int = 5
@export_range(1, 3) var cards_per_turn_draw: int = 1

signal duel_started
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal card_played(card)
signal duel_ended(winner: String)
signal enemy_card_played(card: CardData)

# Components
var flow_controller: DuelFlowController
var ai_controller: EnemyAIController
var card_resolver: CardResolver
var passive_handler: ClassPassiveHandler
var sequence_handler: DuelSequenceHandler
var sanity_tracker: SanityThresholdTracker

# Removed EffectProcessor dependency

func _ready():
	GLog.info("DuelManager initializing...")

	if not duel_state:
		duel_state = DuelState.new()
		GLog.info("Created new DuelState")

	# Initialize components
	flow_controller = DuelFlowController.new(duel_state)
	ai_controller = EnemyAIController.new(duel_state)
	card_resolver = CardResolver.new(duel_state, self) # Removed effect_processor arg
	passive_handler = ClassPassiveHandler.new(duel_state)
	sequence_handler = DuelSequenceHandler.new()
	
	# Wire inter-component references
	flow_controller.card_resolver = card_resolver
	flow_controller.ai_controller = ai_controller
	
	# Wire component signals to DuelManager signals
	flow_controller.turn_started.connect(_on_flow_controller_turn_started)
	flow_controller.turn_ended.connect(_on_flow_controller_turn_ended)
	flow_controller.duel_ended.connect(_on_flow_controller_duel_ended)
	card_resolver.card_played.connect(_on_card_resolver_card_played)
	card_resolver.enemy_card_played.connect(_on_card_resolver_enemy_card_played)

	duel_state.add_change_listener(_on_duel_state_changed)
	
	# Initialize sanity threshold tracker for curse injection
	sanity_tracker = SanityThresholdTracker.new()
	sanity_tracker.corruption_triggered.connect(_on_corruption_triggered)
	sanity_tracker.tier_changed.connect(_on_sanity_tier_changed)

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	GLog.debug("DuelState changed: %s" % change_type)
	
	match change_type:
		"player_died", "player_went_insane":
			end_duel("enemy")
		"enemy_died":
			end_duel("player")
		"player_sanity_changed", "player_sanity_tier_changed":
			# Check sanity thresholds when sanity changes
			if sanity_tracker and duel_state and duel_state.player_data:
				sanity_tracker.check_threshold(duel_state.player_data)

# Sanity threshold tracking handlers
func _on_sanity_tier_changed(old_tier: int, new_tier: int) -> void:
	"""Handle sanity tier transition - log for debugging"""
	var old_name = Stats.get_tier_name(old_tier)
	var new_name = Stats.get_tier_name(new_tier)
	GLog.info("DuelManager: Sanity tier changed: %s -> %s" % [old_name, new_name])
	
	# Emit event for UI to show visual feedback
	if EventBus:
		EventBus.emit_ui_notification("Mental state: " + new_name, "warning" if new_tier > old_tier else "info")

func _on_corruption_triggered(tier: int, card_path: String) -> void:
	"""Handle corruption event - inject curse card into run deck (persistent until rest)"""
	if not ResourceLoader.exists(card_path):
		GLog.error("DuelManager: Curse card not found: %s" % card_path)
		return
	
	var curse_card = load(card_path) as CardData
	if not curse_card:
		GLog.error("DuelManager: Failed to load curse card: %s" % card_path)
		return
	
	# Add curse to run deck (persistent until rest site removes it)
	if DeckManager and DeckManager.is_deck_available():
		DeckManager.add_card(curse_card)
		var tier_name = Stats.get_tier_name(tier)
		GLog.info("DuelManager: Corrupted! '%s' permanently added to deck (tier: %s)" % [curse_card.card_name, tier_name])
		
		# Notify player of the corruption
		if EventBus:
			EventBus.emit_ui_notification("Mind corrupted! " + curse_card.card_name + " added to deck", "error")
	else:
		GLog.warn("DuelManager: Cannot inject curse - DeckManager not available")

# Signal forwarding methods
func _on_flow_controller_turn_started(is_player_turn: bool) -> void:
	turn_started.emit(is_player_turn)
	
	# If it's enemy turn, execute AI
	if not is_player_turn:
		await _execute_enemy_turn()

func _on_flow_controller_turn_ended(is_player_turn: bool) -> void:
	turn_ended.emit(is_player_turn)

func _on_flow_controller_duel_ended(winner: String) -> void:
	end_duel(winner)

func _on_card_resolver_card_played(card_instance: CardInstance) -> void:
	card_played.emit(card_instance)

func _on_card_resolver_enemy_card_played(card: CardData) -> void:
	enemy_card_played.emit(card)

func start_new_duel(player_deck: DeckData, enemy_data: Resource) -> void:
	GLog.info("DuelManager: Starting new duel...")
	
	# Sync sanity tracker to player state (don't reset - corruption persists across run)
	# Only triggers new corruption if player descends to a NEW tier they haven't hit yet this run
	if sanity_tracker and duel_state and duel_state.player_data:
		sanity_tracker.sync_to_player(duel_state.player_data)
	
	# Setup class passives for the new duel
	passive_handler.setup_passives()
	
	# Delegate to DuelFlowController
	flow_controller.start_duel(player_deck, enemy_data)
	
	duel_started.emit()

func end_player_turn() -> void:
	GLog.debug("DuelManager: Ending player turn")
	
	# Delegate to DuelFlowController
	flow_controller.end_player_turn()

func can_play_card(card_data: CardData) -> bool:
	return card_resolver.can_play_card(card_data)

func play_card(card_instance: CardInstance):
	# Track this card for enemy memory
	track_player_card_for_enemy_memory(card_instance.card_data)
	
	# Delegate to CardResolver
	card_resolver.play_player_card(card_instance)

func end_duel(winner: String):
	GLog.info("DuelManager: Duel ended! Winner: %s" % winner)

	# Cleanup class passives
	passive_handler.cleanup()

	# Delegate test sequence handling to DuelSequenceHandler
	var handler_result = sequence_handler.handle_duel_end(winner, duel_state)
	
	if handler_result.handled:
		# Test sequence handler took care of everything
		if handler_result.should_emit_signals:
			duel_ended.emit(winner)
		
		if handler_result.scene_to_load:
			await get_tree().create_timer(GameConstants.TIMING_VALUES["scene_transition_delay"]).timeout
			# Use intent-based loading if available
			if handler_result.has("intent") and handler_result.intent:
				SceneManager.load_scene_with_intent(handler_result.scene_to_load, handler_result.intent)
			else:
				SceneManager.load_scene(handler_result.scene_to_load)
		else:
			# Handled, but no scene change -> Sequence Continue
			GLog.info("DuelManager: Sequence continuing to next battle...")
			var next_config = sequence_handler.start_next_battle()
			if next_config:
				# Brief pause between battles
				await get_tree().create_timer(GameConstants.TIMING_VALUES["scene_transition_delay"]).timeout
				
				# Start the next duel using the config
				flow_controller.start_duel_with_config(next_config)
				
				# Re-setup passives for the new duel
				passive_handler.setup_passives()
				
				duel_started.emit()
			else:
				GLog.error("DuelManager: Failed to get next battle config from sequence handler")
				
		return

	# Normal (non-test) duel - do state cleanup
	duel_state.end_duel(winner)

	if winner == "player":
		# Check if this enemy should offer curio reward (boss/elite only)
		var should_offer_curio = _should_offer_curio_reward()

		# Store flag for victory reward scene
		if GameManager:
			GameManager.game_data["pending_curio_reward"] = should_offer_curio
			if should_offer_curio:
				GLog.info("DuelManager: Elite/Boss defeated! Curio reward will be offered")

		# Load victory reward scene for card selection
		await get_tree().create_timer(GameConstants.TIMING_VALUES["scene_transition_delay"]).timeout
		SceneManager.load_scene("res://scenes/ui/victory_reward.tscn")
	else:
		# Player lost - go to game over or appropriate scene
		await get_tree().create_timer(GameConstants.TIMING_VALUES["scene_transition_delay"]).timeout
		SceneManager.load_scene_by_name("game_over")

	duel_ended.emit(winner)

func _should_offer_curio_reward() -> bool:
	"""Check if defeated enemy should offer a curio reward (boss/elite only)"""
	if not duel_state or not duel_state.enemy_data:
		return false

	var enemy = duel_state.enemy_data

	# Check for boss
	if "is_boss" in enemy and enemy.is_boss:
		GLog.debug("DuelManager: Boss enemy defeated - curio reward triggered")
		return true

	# Check for elite
	if "is_elite" in enemy and enemy.is_elite:
		GLog.debug("DuelManager: Elite enemy defeated - curio reward triggered")
		return true

	return false

func get_hand_cards() -> Array[CardInstance]:
	return duel_state.hand.cards if duel_state.hand else []

# Compatibility method for UI that expects CardData
func get_hand_card_data() -> Array[CardData]:
	if duel_state and duel_state.hand:
		return duel_state.hand.get_card_data_array()
	return []

func get_deck_count() -> int:
	return duel_state.deck.size() if duel_state.deck else 0

func get_discard_count() -> int:
	return duel_state.discard_pile.size() if duel_state.discard_pile else 0

func get_removed_count() -> int:
	return duel_state.removed_pile.size() if duel_state.removed_pile else 0

func get_cards_played_this_turn() -> int:
	if duel_state and duel_state.player_data:
		return duel_state.player_data.cards_played_this_turn
	return 0

func get_player_gold() -> int:
	if duel_state and duel_state.player_data:
		return duel_state.player_data.gold
	return 0

func get_player_health() -> int:
	if duel_state and duel_state.player_data:
		return duel_state.player_data.current_health
	return 0

func get_enemy_health() -> int:
	if duel_state and duel_state.enemy_data:
		return duel_state.enemy_data.current_health
	return 0

func track_player_card_for_enemy_memory(card: CardData):
	"""Track cards played by player for enemy AI adaptation"""
	var enemy = duel_state.enemy_data as EnemyState
	if enemy:
		enemy.add_to_player_memory(card.card_name)

func _execute_enemy_turn() -> void:
	"""Execute the enemy AI turn"""
	if not duel_state or not duel_state.enemy_data:
		GLog.error("DuelManager: Cannot execute enemy turn - no enemy data")
		flow_controller.end_enemy_turn()
		return
	
	var enemy = duel_state.enemy_data as EnemyState
	if not enemy:
		GLog.error("DuelManager: Enemy data is not EnemyState")
		flow_controller.end_enemy_turn()
		return
	
	# Execute AI turn and wait for all enemy card plays to finish.
	await ai_controller.execute_turn(enemy, card_resolver)

	# Wait for enemy AI to complete before ending turn
	await get_tree().create_timer(GameConstants.TIMING_VALUES["enemy_turn_end_delay"]).timeout
	flow_controller.end_enemy_turn()
