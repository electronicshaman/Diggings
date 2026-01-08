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

# Timing constants
const ENEMY_TURN_START_DELAY: float = 1.0

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
	
	# Draw cards for turn (except first turn which already drew initial hand)
	if duel_state.player_turn_count > 1:
		var cards_per_turn_draw = 1 # Standard card draw per turn
		var drawn = duel_state.draw_cards(cards_per_turn_draw)
		if drawn.size() > 0:
			GLog.debug("DuelFlowController: Drew %d card(s) for turn" % drawn.size())
	
	turn_started.emit(true)

func end_player_turn() -> void:
	"""Process end-of-turn effects, emit signal"""
	GLog.debug("DuelFlowController: Ending player turn")
	
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
		start_enemy_turn()

func start_enemy_turn() -> void:
	"""Increment turn count, emit signal"""
	GLog.info("DuelFlowController: Starting enemy turn %d" % (duel_state.enemy_turn_count + 1))
	
	duel_state.start_enemy_turn()
	turn_started.emit(false)
	
	# Note: Enemy AI execution will be handled by EnemyAIController

func end_enemy_turn() -> void:
	"""Emit signal, check for next turn"""
	GLog.debug("DuelFlowController: Ending enemy turn")
	
	duel_state.end_enemy_turn()
	turn_ended.emit(false)
	
	# Check for win/loss conditions
	var winner = check_win_loss_conditions()
	if winner != "":
		duel_ended.emit(winner)
		return
	
	# Check if duel is over before starting next player turn
	if not is_duel_over():
		start_player_turn()

# Helper methods
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