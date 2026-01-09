class_name DuelSequenceHandler
extends RefCounted

## DuelSequenceHandler
# Manages multi-battle duel sequences independently from regular duel flow
# Handles sequence detection, progression, and state management

const DEBUG_ENABLED: bool = true

func _init() -> void:
	GLog.debug("DuelSequenceHandler initialized", "duel_sequence_handler")

# ============================================================================
# Sequence Detection Methods
# ============================================================================

func is_quick_duel() -> bool:
	"""Check if current duel is a quick duel by examining GameManager flag"""
	return GameManager.game_data.get("is_quick_duel", false)

func is_sequence_active() -> bool:
	"""Check if a duel sequence is currently active"""
	return GameManager.duel_sequence_state != null and GameManager.duel_sequence_state.is_active

# ============================================================================
# Duel End Handling
# ============================================================================

func handle_duel_end(winner: String, _duel_state: DuelState) -> Dictionary:
	"""
	Route duel end based on quick duel/sequence state
	Returns dictionary with scene routing information
	"""
	# Default response for non-quick duels
	var response = {
		"handled": false,
		"scene_to_load": "",
		"should_emit_signals": true
	}

	# If not a quick duel, don't interfere
	if not is_quick_duel():
		return response

	# Handle quick duel end logic
	var seq_state = GameManager.duel_sequence_state
	if not seq_state:
		# Single quick duel
		# Check if rewards should be shown
		if GameManager.game_data.get("show_quick_duel_rewards", false):
			var intent = RewardIntent.create_quick_duel_reward(false, "quick_duel_setup")
			GLog.info("Single quick duel victory - routing to rewards", "duel_sequence_handler")
			response.handled = true
			response.scene_to_load = "res://scenes/ui/victory_reward.tscn"
			response.intent = intent
			response.should_emit_signals = true
			return response
			
		# Return to quick duel setup if no rewards
		response.handled = true
		response.scene_to_load = "res://scenes/game/quick_duel_setup.tscn"
		response.should_emit_signals = true
		return response
	
	# Handle sequence logic
	if winner == "enemy":
		# Defeat - reset sequence and return to setup
		reset_sequence()
		response.handled = true
		response.scene_to_load = "res://scenes/game/quick_duel_setup.tscn"
		response.should_emit_signals = true
		return response
	
	# Victory
	# Check if this was the last enemy
	# Note: current_enemy_index is 0-based, so if index + 1 == total, we just finished the last one
	var is_last_battle = (seq_state.current_enemy_index + 1) >= seq_state.total_enemies
	
	if is_last_battle:
		# Sequence complete!
		GLog.info("Sequence complete (last enemy defeated)", "duel_sequence_handler")
		
		# Check if we should show rewards for the final battle
		if seq_state.show_rewards:
			# Show victory screen, but route to run completion instead of back to duel
			# We pass continue_sequence=false so VictoryReward doesn't try to advance and loop back
			var intent = RewardIntent.create_quick_duel_reward(false, "run_complete")
			
			# Construct the RunCompleteIntent to be used AFTER rewards
			# Since RewardIntent just takes a string path, we rely on the scene loading
			# However, we need to pass the "Run Complete" state.
			# For now, we'll route to the RunComplete scene.
			
			GLog.info("Last battle victory - routing to final rewards then run complete", "duel_sequence_handler")
			response.handled = true
			response.scene_to_load = "res://scenes/ui/victory_reward.tscn"
			response.intent = intent
			response.should_emit_signals = true
			
			# We do NOT reset sequence yet, so VictoryReward can read any stats if needed
			# But we must ensure it gets reset eventually. 
			# RunCompleteScene will take over.
			reset_sequence()
			
			return response
		else:
			# Return to run completion directly
			reset_sequence()
			var intent = RunCompleteIntent.new(true, "quick_duel_setup")
			response.handled = true
			response.scene_to_load = "res://scenes/ui/run_complete.tscn"
			response.intent = intent
			response.should_emit_signals = true
			return response
	else:
		# Continue sequence - check if rewards should be shown between battles
		if seq_state.show_rewards:
			# Show victory screen with intent, then continue sequence
			var intent = RewardIntent.create_quick_duel_reward(true, "duel")
			GLog.info("Sequence victory - routing to rewards before next battle", "duel_sequence_handler")
			response.handled = true
			response.scene_to_load = "res://scenes/ui/victory_reward.tscn"
			response.intent = intent
			response.should_emit_signals = true
			return response
		else:
			# Skip rewards - advance and start next battle directly
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
	var seq_state = GameManager.duel_sequence_state
	if not seq_state or not seq_state.is_active:
		GLog.error("Cannot start next battle - no active sequence", "duel_sequence_handler")
		return null
	
	var next_enemy = seq_state.get_next_enemy()
	if not next_enemy:
		GLog.error("Cannot start next battle - no next enemy", "duel_sequence_handler")
		return null
		
	# Duplicate the enemy resource to ensure a fresh state (full health, etc.)
	# We use deep duplicate (true) to also duplicate sub-resources like Stats
	next_enemy = next_enemy.duplicate(true)
	
	# Create deck from DeckManager (runtime deck includes rewards) or fall back to original
	var deck_cards: Array[CardData] = []
	GLog.info("Preparing next battle deck...", "duel_sequence_handler")
	
	# Priority 1: Use DeckManager if available (contains cards added during run)
	if DeckManager and DeckManager.is_deck_available():
		deck_cards = DeckManager.get_current_deck()
		GLog.info("Loaded %d cards from DeckManager (runtime deck)" % deck_cards.size(), "duel_sequence_handler")
	# Priority 2: Fall back to original deck data from sequence state
	elif seq_state.selected_deck:
		if "cards" in seq_state.selected_deck:
			# Handle explicit card list (e.g. ad-hoc deck)
			deck_cards = seq_state.selected_deck.cards.duplicate()
		elif "card_paths" in seq_state.selected_deck:
			# Handle DeckData resource
			var paths = seq_state.selected_deck.card_paths
			GLog.info("Loading %d cards from paths (fallback)" % paths.size(), "duel_sequence_handler")
			for path in paths:
				var card = load(path) as CardData
				if card:
					deck_cards.append(card)
				else:
					GLog.warn("Failed to load card at path: %s" % path, "duel_sequence_handler")
	
	GLog.info("Creating DuelConfig with %d cards and enemy %s" % [deck_cards.size(), next_enemy], "duel_sequence_handler")

	# Create DuelConfig with quick duel modifiers
	var config = DuelConfig.new(
		deck_cards,
		next_enemy,
		"duel_sequence",
		{"quick_duel": true}
	)

	GLog.info("Created DuelConfig successfully", "duel_sequence_handler")
	return config

func get_persistent_state() -> Dictionary:
	"""Return health/energy to persist between battles"""
	var seq_state = GameManager.duel_sequence_state
	if not seq_state:
		return {}

	return {
		"health": seq_state.persistent_health,
		"energy": seq_state.persistent_energy
	}

func reset_sequence() -> void:
	"""Clear all sequence state"""
	if GameManager.duel_sequence_state:
		GameManager.duel_sequence_state.reset()
		GameManager.duel_sequence_state = null
		GLog.info("Duel sequence reset", "duel_sequence_handler")

	# Clear quick duel flag
	GameManager.game_data["is_quick_duel"] = false
