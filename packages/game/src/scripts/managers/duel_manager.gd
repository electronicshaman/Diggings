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
var test_handler: TestSequenceHandler

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
	test_handler = TestSequenceHandler.new()
	
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

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	GLog.debug("DuelState changed: %s" % change_type)
	
	match change_type:
		"player_died", "player_went_insane":
			end_duel("enemy")
		"enemy_died":
			end_duel("player")

# Signal forwarding methods
func _on_flow_controller_turn_started(is_player_turn: bool) -> void:
	turn_started.emit(is_player_turn)
	
	# If it's enemy turn, execute AI
	if not is_player_turn:
		_execute_enemy_turn()

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

	# Delegate test sequence handling to TestSequenceHandler
	var handler_result = test_handler.handle_duel_end(winner, duel_state)
	
	if handler_result.handled:
		# Test sequence handler took care of everything
		if handler_result.should_emit_signals:
			duel_ended.emit(winner)
		
		if handler_result.scene_to_load:
			await get_tree().create_timer(0.5).timeout
			SceneManager.load_scene(handler_result.scene_to_load)
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
		await get_tree().create_timer(1.0).timeout # Brief pause before transition
		SceneManager.load_scene("res://scenes/ui/victory_reward.tscn")
	else:
		# Player lost - go to game over or appropriate scene
		await get_tree().create_timer(1.0).timeout
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
	
	# Execute AI turn asynchronously
	ai_controller.execute_turn(enemy, card_resolver)
	
	# Wait a moment then end the enemy turn
	await get_tree().create_timer(2.0).timeout
	flow_controller.end_enemy_turn()
