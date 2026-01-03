extends Node
class_name DuelManager

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Timing constants for card playing
const CARD_STAGE_DELAY: float = 0.5  # Time card sits on battlefield before resolving
const ENEMY_CARD_PLAY_DELAY: float = 1.5  # Time between enemy card plays  
const ENEMY_TURN_START_DELAY: float = 1.0  # Delay before enemy starts

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

var card_effects_processor: CardEffects

func _ready():
	GLog.info("DuelManager initializing...")

	if not duel_state:
		duel_state = DuelState.new()
		GLog.info("Created new DuelState")

	card_effects_processor = CardEffects.new()

	duel_state.add_change_listener(_on_duel_state_changed)

	# Connect Preacher passive abilities to EventBus
	_setup_preacher_passive_abilities()

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	GLog.debug("DuelState changed: %s" % change_type)
	
	match change_type:
		"player_died", "player_went_insane":
			end_duel("enemy")
		"enemy_died":
			end_duel("player")

func start_new_duel(player_deck: DeckData, enemy_data: Resource) -> void:
	GLog.info("Starting new duel...")
	
	# Debug enemy health before assignment
	if enemy_data and enemy_data.has_method("get") and enemy_data.stats:
		GLog.debug("Enemy loaded with HP: %d/%d" % [enemy_data.stats.current_health, enemy_data.stats.max_health])
	
	duel_state.enemy_data = enemy_data
	
	# Debug enemy health after assignment
	if duel_state.enemy_data and duel_state.enemy_data.stats:
		GLog.debug("Enemy assigned to duel_state with HP: %d/%d" % [duel_state.enemy_data.stats.current_health, duel_state.enemy_data.stats.max_health])
	
	# Batch notifications during duel setup to avoid UI flicker/resets
	if duel_state and duel_state.has_method("begin_batch_changes"):
		duel_state.begin_batch_changes()

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
			GLog.error("Failed to load card from DeckData: %s" % card_path)
	
	duel_state.deck.shuffle()
	
	duel_state.start_duel()
	
	# Load enemy deck
	load_enemy_deck(enemy_data as EnemyState)
	
	# Draw initial enemy hand
	var enemy_initial_draw = (enemy_data as EnemyState).draw_cards(5)
	GLog.info("Drew initial enemy hand: %d cards" % enemy_initial_draw.size())
	
	draw_initial_hand()
	
	duel_started.emit()
	
	# End batch and emit a consolidated update once everything is ready
	if duel_state and duel_state.has_method("end_batch_changes"):
		duel_state.end_batch_changes()
	
	start_player_turn()

func draw_initial_hand() -> void:
	var drawn = duel_state.draw_cards(initial_hand_size)
	GLog.info("Drew initial hand of %d cards" % drawn.size())

func start_player_turn() -> void:
	GLog.info("Starting player turn %d" % (duel_state.player_turn_count + 1))
	
	duel_state.start_player_turn()
	
	if duel_state.player_turn_count > 1:
		var drawn = duel_state.draw_cards(cards_per_turn_draw)
		if drawn.size() > 0:
			GLog.debug("Drew %d card(s) for turn" % drawn.size())
	
	turn_started.emit(true)

func end_player_turn() -> void:
	GLog.debug("Ending player turn")
	
	# No battlefield resolution needed - cards resolve immediately when played
	
	# Process player end-of-turn effects (like delayed damage)
	if duel_state.player_data:
		duel_state.player_data.end_turn()
	
	duel_state.end_player_turn()
	turn_ended.emit(true)
	
	if not duel_state.is_duel_over():
		start_enemy_turn()

func start_enemy_turn():
	GLog.info("Starting enemy turn %d" % (duel_state.enemy_turn_count + 1))
	
	duel_state.start_enemy_turn()
	turn_started.emit(false)
	
	# Add delay before enemy starts acting
	await get_tree().create_timer(ENEMY_TURN_START_DELAY).timeout
	
	process_enemy_turn()

func process_enemy_turn():
	var enemy = duel_state.enemy_data as EnemyState
	
	if enemy.is_stunned():
		GLog.debug("Enemy is stunned, skipping turn")
		enemy.reduce_stun()
		end_enemy_turn()
		return
	
	# Draw cards at start of enemy turn
	var cards_to_draw = min(enemy.cards_per_turn, enemy.hand_size_limit - enemy.enemy_hand.size())
	if cards_to_draw > 0:
		var drawn = enemy.draw_cards(cards_to_draw)
		GLog.debug("Enemy drew %d cards" % drawn.size())
	
	# Reset enemy energy for this turn
	if enemy.stats:
		enemy.stats.current_energy = enemy.stats.max_energy
	
	# Execute enemy AI to play cards
	await execute_enemy_ai_turn(enemy)
	
	end_enemy_turn()

func load_enemy_deck(enemy: EnemyState):
	"""Load the enemy's deck from configured card paths"""
	GLog.info("Loading enemy deck for %s" % enemy.enemy_name)
	
	# Clear existing piles
	enemy.enemy_hand.clear()
	enemy.enemy_discard.clear()
	
	# Initialize deck from DeckData resource or legacy paths
	enemy.initialize_deck_from_data()
	
	# Shuffle the deck
	enemy.enemy_deck.shuffle()
	GLog.info("Enemy deck loaded: %d cards" % enemy.enemy_deck.size())

func execute_enemy_ai_turn(enemy: EnemyState):
	"""Execute the enemy's AI to play cards from hand"""
	GLog.info("Enemy AI (%s) is taking its turn" % enemy.ai_type)
	
	var cards_played = 0
	var max_cards_to_play = 3  # Limit cards per turn for balance
	
	# Get playable cards based on energy
	var playable_cards = get_enemy_playable_cards(enemy)
	
	while playable_cards.size() > 0 and cards_played < max_cards_to_play:
		var card_to_play = select_card_by_ai_type(enemy, playable_cards)
		
		if card_to_play:
			await play_enemy_card(enemy, card_to_play)
			cards_played += 1
			
			# Add delay between card plays for readability
			if cards_played < max_cards_to_play:
				await get_tree().create_timer(ENEMY_CARD_PLAY_DELAY).timeout
			
			# Update playable cards after spending energy
			playable_cards = get_enemy_playable_cards(enemy)
		else:
			break
	
	if cards_played == 0:
		GLog.info("Enemy couldn't play any cards this turn")
	else:
		GLog.info("Enemy played %d cards this turn" % cards_played)

func get_enemy_playable_cards(enemy: EnemyState) -> Array[CardData]:
	"""Get cards the enemy can afford to play (map from CardInstance to CardData)"""
	var playable: Array[CardData] = []
	var current_energy = enemy.stats.current_energy if enemy.stats else 0
	
	for inst in enemy.enemy_hand.cards:
		var cd: CardData = inst.card_data if inst else null
		if cd and cd.energy_cost <= current_energy:
			playable.append(cd)
	
	return playable

func select_card_by_ai_type(enemy: EnemyState, playable_cards: Array[CardData]) -> CardData:
	"""Select which card to play based on AI personality"""
	if playable_cards.is_empty():
		return null
	
	match enemy.ai_type:
		"aggressive":
			# Prioritize attack cards
			for card in playable_cards:
				if card.mechanical_category == "Attack":
					return card
			# Fall back to any card
			return playable_cards[0]
		
		"defensive":
			# Prioritize skill/defense cards
			for card in playable_cards:
				if card.mechanical_category == "Skill":
					return card
			# Fall back to cheapest card
			var cheapest = playable_cards[0]
			for card in playable_cards:
				if card.energy_cost < cheapest.energy_cost:
					cheapest = card
			return cheapest
		
		"balanced":
			# Mix of attack and defense based on situation
			var player_health_ratio = duel_state.player_data.stats.get_health_percentage()
			var enemy_health_ratio = enemy.stats.get_health_percentage()
			
			if enemy_health_ratio < 0.3:
				# Low health, play defensively
				for card in playable_cards:
					if card.mechanical_category == "Skill":
						return card
			elif player_health_ratio < 0.3:
				# Player low health, be aggressive
				for card in playable_cards:
					if card.mechanical_category == "Attack":
						return card
			
			# Default: play highest cost card we can afford
			var best = playable_cards[0]
			for card in playable_cards:
				if card.energy_cost > best.energy_cost:
					best = card
			return best
		
		"cunning":
			# Adapt based on player patterns
			var most_played = enemy.get_player_most_played_card()
			
			# Try to counter common player patterns
			if "Strike" in most_played or "Attack" in most_played:
				# Player plays lots of attacks, prioritize defense
				for card in playable_cards:
					if card.mechanical_category == "Skill":
						return card
			elif "Block" in most_played or "Defend" in most_played:
				# Player plays defensively, be aggressive
				for card in playable_cards:
					if card.mechanical_category == "Attack":
						return card
			
			# Default: random selection for unpredictability
			return playable_cards[randi() % playable_cards.size()]
		
		_:
			# Default AI: play first available card
			return playable_cards[0]

func play_enemy_card(enemy: EnemyState, card: CardData):
	"""Play an enemy card with immediate resolution"""
	GLog.info("Enemy plays: %s (Cost: %d)" % [card.card_name, card.energy_cost])
	
	# Spend energy upfront
	if enemy.stats:
		enemy.stats.current_energy -= card.energy_cost
	
	# Move card from enemy hand to battlefield temporarily
	var staged_instance: CardInstance = null
	if enemy.enemy_hand.remove_card_data(card):
		duel_state.battlefield.add_card_data(card)
		# Retrieve the actual instance we just added so we can resolve/remove the same one
		staged_instance = duel_state.battlefield.find_instance_by_card_data(card)
		GLog.debug("Enemy card '%s' staged on battlefield (instance acquired: %s)" % [card.card_name, str(staged_instance)])
	
	# Emit event for UI to show card
	enemy_card_played.emit(card)
	
	# Wait for player to see the card
	await get_tree().create_timer(ENEMY_CARD_PLAY_DELAY).timeout
	
	# Immediately resolve the card using the staged instance so battlefield removal works
	if staged_instance:
		resolve_single_card(staged_instance, false)
	else:
		# Fallback: if for some reason we couldn't acquire the staged instance, resolve with a temp
		var temp_instance := CardInstance.new(card)
		GLog.warn("Could not find staged instance for enemy card '%s'; resolving with temp instance" % card.card_name)
		resolve_single_card(temp_instance, false)
	
	# Check if duel is over after each card
	if duel_state.is_duel_over():
		var winner = "player" if duel_state.enemy_data.is_dead() else "enemy"
		end_duel(winner)

func end_enemy_turn():
	GLog.debug("Ending enemy turn")
	
	# No battlefield resolution needed - cards resolve immediately when played
	
	duel_state.end_enemy_turn()
	turn_ended.emit(false)
	
	if not duel_state.is_duel_over():
		start_player_turn()

func can_play_card(card_data: CardData) -> bool:
	if not duel_state.can_play_cards():
		return false

	var player = duel_state.player_data
	var actual_cost = player.get_actual_energy_cost(card_data.energy_cost, card_data.card_type)

	# Check energy and sanity costs
	if not player.can_afford_card(actual_cost, card_data.sanity_cost):
		return false

	# Check Faith costs (if any) - look for negative Faith effects
	var faith_cost = _get_faith_cost_from_card(card_data)
	if faith_cost > 0 and not player.can_afford_faith(faith_cost):
		return false

	# Check Custom Resource costs
	var custom_costs = _get_custom_resource_costs_from_card(card_data)
	for resource_name in custom_costs:
		var cost = custom_costs[resource_name]
		if player.get_custom_resource(resource_name) < cost:
			return false

	return true

func play_card(card_instance: CardInstance):
	if not can_play_card(card_instance.card_data):
		GLog.warn("Cannot play card: %s" % card_instance.get_card_name())
		return

	GLog.info("Playing card: %s" % card_instance.get_card_name())

	var player = duel_state.player_data
	var actual_cost = player.get_actual_energy_cost(card_instance.get_energy_cost(), card_instance.get_card_type())

	# Pay all costs upfront to ensure consistent state
	# If card passed can_play_card() check, all costs are guaranteed affordable
	player.pay_energy(actual_cost)
	player.pay_sanity(card_instance.get_sanity_cost())
	
	# Pay Faith costs upfront (extracted from card effects)
	var faith_cost = _get_faith_cost_from_card(card_instance.card_data)
	if faith_cost > 0:
		player.spend_faith(faith_cost)
		GLog.debug("Paid %d Faith cost upfront (current: %d/%d)" % [faith_cost, player.faith, player.max_faith])
	
	# Pay custom resource costs upfront
	var custom_costs = _get_custom_resource_costs_from_card(card_instance.card_data)
	for resource_name in custom_costs:
		var cost = custom_costs[resource_name]
		if cost > 0:
			player.modify_custom_resource(resource_name, -cost)
			GLog.debug("Paid %d %s cost upfront (current: %d)" % [cost, resource_name, player.get_custom_resource(resource_name)])
	
	# Capture timing context BEFORE incrementing counter
	var cards_played_before = player.cards_played_this_turn
	var hand_size_before = duel_state.hand.size() - 1  # -1 because we're about to play this card
	
	# Increment counter for this turn
	player.cards_played_this_turn += 1
	player.apply_card_cost_reductions()
	
	# Move card to battlefield temporarily for visual feedback
	duel_state.play_card(card_instance)
	
	# Emit event for UI to show card on battlefield
	card_played.emit(card_instance)
	
	# Track this card for enemy memory
	track_player_card_for_enemy_memory(card_instance.card_data)
	
	# Brief delay to show card on battlefield
	await get_tree().create_timer(CARD_STAGE_DELAY).timeout
	
	# Immediately resolve the card with timing context
	resolve_single_card_with_context(card_instance, true, cards_played_before, hand_size_before)
	
	# Check if duel is over after each card
	if duel_state.is_duel_over():
		var winner = "player" if duel_state.enemy_data.is_dead() else "enemy"
		end_duel(winner)

func apply_card_results(results: Dictionary):
	var player = duel_state.player_data
	var enemy = duel_state.enemy_data

	if results.has("damage") and results.damage > 0:
		var ignore_defense = results.get("ignores_defense", false)
		var hits: int = int(results.get("damage_hits", 1))
		var total_actual = 0
		var pre_hp = enemy.current_health
		var pre_def = enemy.defense
		GLog.debug("Applying player damage -> amount=%d, hits=%d, ignores_defense=%s | enemy before: %d HP, %d DEF" % [results.damage, max(1, hits), str(ignore_defense), pre_hp, pre_def])
		for i in range(max(1, hits)):
			var actual_damage = enemy.take_damage(results.damage, ignore_defense)
			GLog.debug("  hit %d: actual=%d" % [i + 1, actual_damage])
			total_actual += actual_damage
		player.damage_dealt_this_turn += total_actual
		GLog.info("Dealt %d damage to enemy | after: %d HP, %d DEF" % [total_actual, enemy.current_health, enemy.defense])
	
	if results.has("defense") and results.defense > 0:
		player.gain_defense(results.defense)
		GLog.debug("Gained %d defense" % results.defense)
	
	if results.has("heal") and results.heal > 0:
		player.heal(results.heal)
		GLog.debug("Healed %d health" % results.heal)
	
	if results.has("draw") and results.draw > 0:
		var drawn = duel_state.draw_cards(results.draw)
		GLog.debug("Drew %d cards" % drawn.size())
	
	if results.has("exhaust_random") and results.exhaust_random > 0:
		var exhausted = duel_state.exhaust_random_cards(results.exhaust_random)
		GLog.debug("Exhausted %d cards" % exhausted.size())
	
	if results.has("energy_restore") and results.energy_restore > 0:
		player.restore_energy(results.energy_restore)
		GLog.debug("Restored %d energy" % results.energy_restore)
	
	if results.has("gold") and results.gold != 0:
		if player.stats:
			player.stats.gain_gold(results.gold)
			GLog.debug("Gained %d gold" % results.gold)
			if has_node("/root/EventBus"):
				EventBus.gold_changed.emit(results.gold)
	
	if results.has("stun_enemy") and results.stun_enemy > 0:
		enemy.apply_stun(results.stun_enemy)
		GLog.info("Stunned enemy for %d turns" % results.stun_enemy)
	
	if results.has("delayed_damage") and results.delayed_damage > 0:
		player.delayed_damage += results.delayed_damage
		GLog.debug("Added %d delayed damage (total: %d)" % [results.delayed_damage, player.delayed_damage])

	# Handle Faith effects
	if results.has("faith"):
		var faith_amount = results.faith
		if faith_amount > 0:
			player.gain_faith(faith_amount)
			GLog.debug("Gained %d Faith (current: %d/%d)" % [faith_amount, player.faith, player.max_faith])
		elif faith_amount < 0:
			player.spend_faith(-faith_amount)
			GLog.debug("Spent %d Faith (current: %d/%d)" % [-faith_amount, player.faith, player.max_faith])

	# Handle Custom Resources (Ammo, Brew, etc.)
	if results.has("custom_resources"):
		for resource_name in results.custom_resources:
			var amount = results.custom_resources[resource_name]
			player.modify_custom_resource(resource_name, amount)
			var current = player.get_custom_resource(resource_name)
			if amount > 0:
				GLog.debug("Gained %d %s (total: %d)" % [amount, resource_name, current])
			else:
				GLog.debug("Spent %d %s (total: %d)" % [-amount, resource_name, current])

func apply_enemy_card_results(results: Dictionary, enemy: EnemyState):
	"""Apply card results when enemy plays a card (reversed targets)"""
	var player = duel_state.player_data

	if results.has("damage") and results.damage > 0:
		var hits: int = int(results.get("damage_hits", 1))
		var total_actual = 0
		var pre_hp = player.current_health
		var pre_def = player.defense
		GLog.debug("Applying enemy damage -> amount=%d, hits=%d | player before: %d HP, %d DEF" % [results.damage, max(1, hits), pre_hp, pre_def])
		for i in range(max(1, hits)):
			var actual_damage = player.take_damage(results.damage)
			GLog.debug("  hit %d: actual=%d" % [i + 1, actual_damage])
			total_actual += actual_damage
		GLog.info("Enemy dealt %d damage to player | after: %d HP, %d DEF" % [total_actual, player.current_health, player.defense])
	
	if results.has("defense") and results.defense > 0:
		enemy.gain_defense(results.defense)
		GLog.debug("Enemy gained %d defense" % results.defense)
	
	if results.has("heal") and results.heal > 0:
		enemy.heal(results.heal)
		GLog.debug("Enemy healed %d health" % results.heal)
	
	if results.has("draw") and results.draw > 0:
		var drawn = enemy.draw_cards(results.draw)
		GLog.debug("Enemy drew %d cards" % drawn.size())
	
	if results.has("energy_restore") and results.energy_restore > 0:
		if enemy.stats:
			enemy.stats.restore_energy(results.energy_restore)
		GLog.debug("Enemy restored %d energy" % results.energy_restore)
	
	if results.has("stun_enemy") and results.stun_enemy > 0:
		# Enemy cards that stun would stun the player
		if player.has_method("apply_stun"):
			player.apply_stun(results.stun_enemy)
		GLog.info("Player stunned for %d turns" % results.stun_enemy)

func end_duel(winner: String):
	GLog.info("Duel ended! Winner: %s" % winner)

	# Check if this is a test duel
	var is_test_duel: bool = GameManager.game_data.get("is_test_duel", false)

	if is_test_duel:
		var seq_state = GameManager.test_sequence_state

		# Check for active sequence
		if seq_state and seq_state.is_active:
			if winner == "player":
				# VICTORY in sequence - persist state
				GLog.info("Sequence battle won! Persisting state...", "duel_manager")
				seq_state.persistent_health = duel_state.player_data.current_health
				seq_state.persistent_energy = duel_state.player_data.max_energy
				seq_state.advance_to_next_enemy()

				# Route based on sequence completion and rewards setting
				if seq_state.is_sequence_complete():
					# Sequence complete - call state cleanup then return to test config
					duel_state.end_duel(winner)
					GLog.info("Sequence complete! Returning to test setup", "duel_manager")
					await get_tree().create_timer(0.5).timeout
					SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")
				elif seq_state.show_rewards:
					# More battles remain, show rewards in preview mode
					duel_state.end_duel(winner)
					GLog.info("Showing victory rewards (preview mode)", "duel_manager")
					GameManager.game_data["test_sequence_preview"] = true
					await get_tree().create_timer(0.5).timeout
					SceneManager.load_scene("res://scenes/ui/victory_reward.tscn")
				else:
					# More battles remain, no rewards - start next battle directly
					# Skip duel_state.end_duel() to avoid signal emission during scene transition
					GLog.info("Starting next battle directly (no state cleanup)", "duel_manager")
					await get_tree().create_timer(0.5).timeout
					_start_next_sequence_battle()
					return  # Don't emit signals or clear flags - scene is loading
			else:
				# DEFEAT in sequence - cleanup and return
				duel_state.end_duel(winner)
				var battle_num = seq_state.current_enemy_index + 1
				GLog.warn("Defeated on battle %d/%d" % [battle_num, seq_state.total_enemies], "duel_manager")
				EventBus.emit_ui_notification("Defeated on battle %d/%d" % [battle_num, seq_state.total_enemies], "error")

				# Cleanup
				CurioManager.clear_curios()
				seq_state.reset()
				seq_state.is_active = false

				await get_tree().create_timer(1.0).timeout
				SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")
		else:
			# Single test duel (no sequence) - existing behavior
			duel_state.end_duel(winner)
			GLog.info("Test duel ended, returning to test setup", "duel_manager")
			await get_tree().create_timer(0.5).timeout
			SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")

		# Clear test flag
		GameManager.game_data["is_test_duel"] = false
		duel_ended.emit(winner)
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
				GLog.info("Elite/Boss defeated! Curio reward will be offered")

		# Load victory reward scene for card selection
		await get_tree().create_timer(1.0).timeout  # Brief pause before transition
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
		GLog.debug("Boss enemy defeated - curio reward triggered")
		return true

	# Check for elite
	if "is_elite" in enemy and enemy.is_elite:
		GLog.debug("Elite enemy defeated - curio reward triggered")
		return true

	return false

func _start_next_sequence_battle() -> void:
	"""Start the next battle in a test sequence without returning to config"""
	var seq_state = GameManager.test_sequence_state
	if not seq_state or not seq_state.is_active:
		GLog.warn("Cannot start next sequence battle - no active sequence", "duel_manager")
		return

	var enemy = seq_state.get_next_enemy()
	if not enemy:
		GLog.error("No enemy for next sequence battle", "duel_manager")
		return

	GLog.info("Starting next sequence battle: %d/%d vs %s" % [
		seq_state.current_enemy_index + 1,
		seq_state.total_enemies,
		enemy.get("enemy_name") if enemy.get("enemy_name") else "Unknown"
	], "duel_manager")

	# Convert deck to Array[CardData]
	var player_deck: Array[CardData] = []
	if seq_state.selected_deck and seq_state.selected_deck.has_method("get"):
		for card_path in seq_state.selected_deck.card_paths:
			var card = load(card_path) as CardData
			if card:
				player_deck.append(card)

	if player_deck.is_empty():
		GLog.error("Failed to load deck for sequence - aborting", "duel_manager")
		SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")
		return

	# Create DuelConfig with persistent health/energy
	var modifiers = {
		"test_duel": true,
		"health_override": seq_state.persistent_health,
		"energy_override": seq_state.persistent_energy
	}

	var duel_config = DuelConfig.new(player_deck, enemy, "test_duel", modifiers)
	GameManager.pending_duel_config = duel_config

	# Load the duel scene (using SceneManager for proper cleanup)
	SceneManager.load_scene("res://scenes/game/duel.tscn")

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

func resolve_single_card(card_instance: CardInstance, is_player_card: bool):
	"""Immediately resolve a single card and move it to discard (legacy version)"""
	# Default timing values for compatibility
	var cards_played_before = 0
	var hand_size_before = 0
	
	if is_player_card and duel_state and duel_state.player_data:
		# Try to get reasonable defaults
		cards_played_before = max(0, duel_state.player_data.cards_played_this_turn - 1)
		hand_size_before = duel_state.hand.size()
	
	resolve_single_card_with_context(card_instance, is_player_card, cards_played_before, hand_size_before)

func resolve_single_card_with_context(card_instance: CardInstance, is_player_card: bool, cards_played_before: int, hand_size_before: int):
	"""Immediately resolve a single card with timing context"""
	if not duel_state or not card_instance:
		return
	
	GLog.info("Resolving card: %s" % card_instance.get_card_name())
	
	# Execute card effects WHILE card is still on battlefield - pass the CardInstance to the effects processor with context
	var results = card_effects_processor.apply_card_instance_effects_with_context(
		self, card_instance, cards_played_before, hand_size_before
	)
	
	if is_player_card:
		apply_card_results(results)
		
		# Now remove from battlefield and move to player's final destination
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
		
		GLog.debug("Resolved player card: %s" % card_instance.get_card_name())
	else:
		# Enemy card
		var enemy = duel_state.enemy_data as EnemyState
		apply_enemy_card_results(results, enemy)
		
		# Now remove from battlefield and move enemy card to discard
		duel_state.battlefield.remove_card(card_instance)
		if enemy:
			enemy.enemy_discard.add_card_data(card_instance.card_data)
		
		GLog.debug("Resolved enemy card: %s" % card_instance.get_card_name())

# Minimal getters expected by CardEffects validation
func get_player_data():
	return duel_state.player_data if duel_state else null

func get_enemy_data():
	return duel_state.enemy_data if duel_state else null

func resolve_battlefield():
	"""Process all cards on the battlefield"""
	if not duel_state or not duel_state.battlefield:
		return
	
	GLog.info("Resolving battlefield with %d cards" % duel_state.battlefield.size())
	
	var cards_to_resolve = duel_state.battlefield.cards.duplicate()
	var enemy = duel_state.enemy_data as EnemyState
	
	for card_instance in cards_to_resolve:
		# Remove from battlefield
		duel_state.battlefield.remove_card(card_instance)
		
		# Execute card effects
		var results = card_effects_processor.apply_card_instance_effects(self, card_instance)
		
		# Check card ownership via explicit owner field
		var is_player_card = card_instance.owner == CardInstance.Owner.PLAYER
		
		if is_player_card:
			apply_card_results(results)
			
			# Move to player's final destination
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
			
			GLog.debug("Resolved player card: %s" % card_instance.get_card_name())
		else:
			# Enemy card
			apply_enemy_card_results(results, enemy)
			
			# Move to enemy discard pile
			if enemy:
				enemy.enemy_discard.add_card_data(card_instance.card_data)
			
			GLog.debug("Resolved enemy card: %s" % card_instance.get_card_name())

func resolve_enemy_battlefield():
	"""Enemy cards are now processed in the main resolve_battlefield() function"""
	GLog.debug("Enemy cards resolved through main battlefield resolution")

# Helper function to get Faith cost from card effects
func _get_faith_cost_from_card(card_data: CardData) -> int:
	"""Extract Faith cost from card effects (negative Faith amounts)"""
	if not card_data or not card_data.effects:
		return 0

	var total_faith_cost = 0

	for effect in card_data.effects:
		if effect is FaithEffect:
			var faith_effect = effect as FaithEffect
			# Negative amounts are costs that must be paid
			if faith_effect.amount < 0:
				total_faith_cost += -faith_effect.amount

	return total_faith_cost

func _get_custom_resource_costs_from_card(card_data: CardData) -> Dictionary:
	"""Extract custom resource costs from card effects (negative amounts are costs)"""
	if not card_data or not card_data.effects:
		return {}

	var costs = {}

	for effect in card_data.effects:
		if effect is ResourceEffect:
			var res_effect = effect as ResourceEffect
			# Check if it's a custom resource (not standard)
			# Note: Faith is excluded from standard resources—use FaithEffect instead
			if res_effect.resource_type not in ["gold", "energy", "sanity"]:
				# Both negative and positive amounts; negative = cost, positive = gain
				if res_effect.amount != 0:
					var current_cost = costs.get(res_effect.resource_type, 0)
					costs[res_effect.resource_type] = current_cost + res_effect.amount
	
	return costs

# Setup Preacher passive abilities
func _setup_preacher_passive_abilities():
	"""Connect EventBus signals for Preacher passive abilities"""
	# Fervent Faith: Gain +1 defense when gaining Faith
	if EventBus.has_signal("faith_gained"):
		EventBus.connect_safe("faith_gained", _on_faith_gained_fervent_faith)

	# Temptation: Choice when reaching max Faith
	if EventBus.has_signal("faith_gained"):
		EventBus.connect_safe("faith_gained", _on_faith_gained_temptation_check)
	
	# Holy Conviction: Improve Fortune card success chance based on Faith
	if EventBus.has_signal("gambling_modifier_query"):
		EventBus.connect_safe("gambling_modifier_query", _on_gambling_modifier_query_holy_conviction)

func _on_faith_gained_fervent_faith(player_data, amount: int):
	"""Fervent Faith passive: Gain +1 defense when gaining Faith"""
	if not _is_preacher():
		return

	if amount > 0 and player_data == duel_state.player_data:
		player_data.gain_defense(1)
		GLog.debug("Fervent Faith: Gained 1 defense from Faith gain")

func _on_faith_gained_temptation_check(player_data, _amount: int):
	"""Temptation passive: Trigger choice when reaching max Faith"""
	if not _is_preacher():
		return

	if player_data != duel_state.player_data:
		return

	# Check if player reached max Faith
	if player_data.faith >= player_data.max_faith:
		_trigger_temptation_choice()

func _trigger_temptation_choice():
	"""Trigger the Temptation choice: gold vs corruption"""
	# TODO: This needs a modal dialog UI
	# For now, auto-choose gold (safer option)
	var player = duel_state.player_data
	GLog.info("Temptation triggered! Max Faith reached (%d/%d)" % [player.faith, player.max_faith])

	# Auto-choose gold for now (25 gold, lose all Faith)
	if player.stats:
		player.stats.gain_gold(25)
		player.reset_faith()
		GLog.info("Temptation: Chose gold. Gained 25 gold, lost all Faith")

	# Alternative: gain 3 Corruption and keep Faith
	# player.stats.gain_corruption(3)
	# GLog.info("Temptation: Chose corruption. Gained 3 corruption, kept Faith")

func _is_preacher() -> bool:
	"""Check if player is playing as Preacher class"""
	if not duel_state or not duel_state.player_data:
		return false
	
	var player = duel_state.player_data
	
	# Check character_class resource first
	if player.has("character_class") and player.character_class:
		if player.character_class.has("character_class_name"):
			return player.character_class.character_class_name == "Preacher"
	
	# Fallback to character_class_name property
	if player.has("character_class_name"):
		return player.character_class_name == "Preacher"
	
	return false

func _on_gambling_modifier_query_holy_conviction(player_data: Object, context: Dictionary):
	"""Holy Conviction passive: +10% Fortune card success chance when Faith >= 5"""
	if not _is_preacher():
		return
	
	if player_data != duel_state.player_data:
		return
	
	# Check if player has Faith >= 5
	if player_data.has("faith") and player_data.faith >= 5:
		# Modify success_chance in the context
		if context.has("success_chance"):
			var current_chance: float = context.success_chance
			context.success_chance = min(1.0, current_chance + 0.1)  # Cap at 100%
			GLog.debug("Holy Conviction active! Fortune success chance: %.0f%% -> %.0f%%" % [
				current_chance * 100, context.success_chance * 100
			])

	var player = duel_state.player_data
	if player.character_class and player.character_class.character_class_name == "Preacher":
		return true

	# Fallback: check character_class_name string
	return player.character_class_name == "Preacher"
