class_name TestSequenceHandler
extends RefCounted

## TestSequenceHandler
# Manages test/debug multi-battle sequences independently from production duel flow
# Handles sequence detection, progression, and state management

const DEBUG_ENABLED: bool = true

func _init() -> void:
	GLog.debug("TestSequenceHandler initialized", "test_sequence_handler")

# ============================================================================
# Sequence Detection Methods
# ============================================================================

func is_test_duel() -> bool:
	"""Check if current duel is a test duel by examining GameManager flag"""
	return GameManager.game_data.get("is_test_duel", false)

func is_sequence_active() -> bool:
	"""Check if a test sequence is currently active"""
	return GameManager.test_sequence_state != null and GameManager.test_sequence_state.is_active

# ============================================================================
# Duel End Handling
# ============================================================================

func handle_duel_end(winner: String, _duel_state: DuelState) -> Dictionary:
	"""
	Route duel end based on test/sequence state
	Returns dictionary with scene routing information
	"""
	# Default response for non-test duels
	var response = {
		"handled": false,
		"scene_to_load": "",
		"should_emit_signals": true
	}
	
	# If not a test duel, don't interfere
	if not is_test_duel():
		return response
	
	# Handle test duel end logic
	var seq_state = GameManager.test_sequence_state
	if not seq_state:
		# Single test duel
		# Check if rewards should be shown
		if GameManager.game_data.get("show_test_rewards", false):
			GLog.info("Single test duel victory - routing to rewards", "test_sequence_handler")
			response.handled = true
			response.scene_to_load = "res://scenes/ui/victory_reward.tscn"
			response.should_emit_signals = true
			return response
			
		# Return to test setup if no rewards
		response.handled = true
		response.scene_to_load = "res://scenes/debug/test_duel_setup.tscn"
		response.should_emit_signals = true
		return response
	
	# Handle sequence logic
	if winner == "enemy":
		# Defeat - reset sequence and return to setup
		reset_sequence()
		response.handled = true
		response.scene_to_load = "res://scenes/debug/test_duel_setup.tscn"
		response.should_emit_signals = true
		return response
	
	# Victory - check if sequence continues
	if seq_state.is_sequence_complete():
		# Sequence complete
		reset_sequence()
		response.handled = true
		response.scene_to_load = "res://scenes/debug/test_duel_setup.tscn"
		response.should_emit_signals = true
		return response
	else:
		# Continue sequence - advance and start next battle
		seq_state.advance_to_next_enemy()
		response.handled = true
		response.scene_to_load = "" # Stay in duel scene for next battle
		response.should_emit_signals = false # Don't emit normal end signals
		return response

# ============================================================================
# Sequence Progression
# ============================================================================

func start_next_battle() -> DuelConfig:
	"""Create DuelConfig for the next enemy in the sequence"""
	var seq_state = GameManager.test_sequence_state
	if not seq_state or not seq_state.is_active:
		GLog.error("Cannot start next battle - no active sequence", "test_sequence_handler")
		return null
	
	var next_enemy = seq_state.get_next_enemy()
	if not next_enemy:
		GLog.error("Cannot start next battle - no next enemy", "test_sequence_handler")
		return null
		
	# Duplicate the enemy resource to ensure a fresh state (full health, etc.)
	# We use deep duplicate (true) to also duplicate sub-resources like Stats
	next_enemy = next_enemy.duplicate(true)
	
	# Create deck from selected deck data
	var deck_cards: Array[CardData] = []
	GLog.info("Preparing next battle deck...", "test_sequence_handler")
	if seq_state.selected_deck:
		if "cards" in seq_state.selected_deck:
			# Handle explicit card list (e.g. ad-hoc deck)
			deck_cards = seq_state.selected_deck.cards.duplicate()
		elif "card_paths" in seq_state.selected_deck:
			# Handle DeckData resource
			var paths = seq_state.selected_deck.card_paths
			GLog.info("Loading %d cards from paths" % paths.size(), "test_sequence_handler")
			for path in paths:
				var card = load(path) as CardData
				if card:
					deck_cards.append(card)
				else:
					GLog.warn("Failed to load card at path: %s" % path, "test_sequence_handler")
	
	GLog.info("Creating DuelConfig with %d cards and enemy %s" % [deck_cards.size(), next_enemy], "test_sequence_handler")
	
	# Create DuelConfig with test modifiers
	var config = DuelConfig.new(
		deck_cards,
		next_enemy,
		"test_sequence",
		{"test_duel": true}
	)
	
	GLog.info("Created DuelConfig successfully", "test_sequence_handler")
	return config

func get_persistent_state() -> Dictionary:
	"""Return health/energy to persist between battles"""
	var seq_state = GameManager.test_sequence_state
	if not seq_state:
		return {}
	
	return {
		"health": seq_state.persistent_health,
		"energy": seq_state.persistent_energy
	}

func reset_sequence() -> void:
	"""Clear all sequence state"""
	if GameManager.test_sequence_state:
		GameManager.test_sequence_state.reset()
		GameManager.test_sequence_state = null
		GLog.info("Test sequence reset", "test_sequence_handler")
	
	# Clear test duel flag
	GameManager.game_data["is_test_duel"] = false
