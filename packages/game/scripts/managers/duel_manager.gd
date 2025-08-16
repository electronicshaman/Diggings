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
signal card_played(card: CardData)
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

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	GLog.debug("DuelState changed: %s" % change_type)
	
	match change_type:
		"player_died", "player_went_insane":
			end_duel("enemy")
		"enemy_died":
			end_duel("player")

func start_new_duel(player_deck: Array[CardData], enemy_data: Resource) -> void:
	GLog.info("Starting new duel...")
	
	duel_state.enemy_data = enemy_data
	
	duel_state.deck.clear()
	duel_state.discard_pile.clear()
	duel_state.hand.clear()
	duel_state.removed_pile.clear()
	
	# Convert CardData array to CardInstance array
	for card_data in player_deck:
		duel_state.deck.add_card_data(card_data)
	
	duel_state.deck.shuffle()
	
	duel_state.start_duel()
	
	# Load enemy deck
	load_enemy_deck(enemy_data as EnemyState)
	
	# Draw initial enemy hand
	var enemy_initial_draw = (enemy_data as EnemyState).draw_cards(5)
	GLog.info("Drew initial enemy hand: %d cards" % enemy_initial_draw.size())
	
	draw_initial_hand()
	
	duel_started.emit()
	
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
	"""Get cards the enemy can afford to play"""
	var playable: Array[CardData] = []
	var current_energy = enemy.stats.current_energy if enemy.stats else 0
	
	for card in enemy.enemy_hand.cards:
		if card.energy_cost <= current_energy:
			playable.append(card)
	
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
	if enemy.enemy_hand.remove_card_data(card):
		duel_state.battlefield.add_card_data(card)
		GLog.debug("Enemy card '%s' staged on battlefield" % card.card_name)
	
	# Emit event for UI to show card
	enemy_card_played.emit(card)
	
	# Wait for player to see the card
	await get_tree().create_timer(ENEMY_CARD_PLAY_DELAY).timeout
	
	# Immediately resolve the card
	# Convert CardData to a temporary instance for resolution
	var temp_instance := CardInstance.new(card)
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
	
	return player.can_afford_card(actual_cost, card_data.sanity_cost)

func play_card(card_instance: CardInstance):
	if not can_play_card(card_instance.card_data):
		GLog.warn("Cannot play card: %s" % card_instance.get_card_name())
		return
	
	GLog.info("Playing card: %s" % card_instance.get_card_name())
	
	var player = duel_state.player_data
	var actual_cost = player.get_actual_energy_cost(card_instance.get_energy_cost(), card_instance.get_card_type())
	
	# Pay costs upfront
	player.pay_energy(actual_cost)
	player.pay_sanity(card_instance.get_sanity_cost())
	
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
	
	# Immediately resolve the card
	resolve_single_card(card_instance, true)
	
	# Check if duel is over after each card
	if duel_state.is_duel_over():
		var winner = "player" if duel_state.enemy_data.is_dead() else "enemy"
		end_duel(winner)

func apply_card_results(results: Dictionary):
	var player = duel_state.player_data
	var enemy = duel_state.enemy_data
	
	if results.has("damage") and results.damage > 0:
		var ignore_defense = results.get("ignores_defense", false)
		var actual_damage = enemy.take_damage(results.damage, ignore_defense)
		player.damage_dealt_this_turn += actual_damage
		GLog.info("Dealt %d damage to enemy" % actual_damage)
	
	if results.has("defense") and results.defense > 0:
		player.gain_defense(results.defense)
		GLog.debug("Gained %d defense" % results.defense)
	
	if results.has("heal") and results.heal > 0:
		player.heal(results.heal)
		GLog.debug("Healed %d health" % results.heal)
	
	if results.has("draw") and results.draw > 0:
		var drawn = duel_state.draw_cards(results.draw)
		GLog.debug("Drew %d cards" % drawn.size())
	
	if results.has("energy_restore") and results.energy_restore > 0:
		player.restore_energy(results.energy_restore)
		GLog.debug("Restored %d energy" % results.energy_restore)
	
	if results.has("stun_enemy") and results.stun_enemy > 0:
		enemy.apply_stun(results.stun_enemy)
		GLog.info("Stunned enemy for %d turns" % results.stun_enemy)
	
	if results.has("delayed_damage") and results.delayed_damage > 0:
		player.delayed_damage += results.delayed_damage
		GLog.debug("Added %d delayed damage (total: %d)" % [results.delayed_damage, player.delayed_damage])

func apply_enemy_card_results(results: Dictionary, enemy: EnemyState):
	"""Apply card results when enemy plays a card (reversed targets)"""
	var player = duel_state.player_data
	
	if results.has("damage") and results.damage > 0:
		var actual_damage = player.take_damage(results.damage)
		GLog.info("Enemy dealt %d damage to player" % actual_damage)
	
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
	duel_state.end_duel(winner)
	
	# Check for curio rewards on player victory
	if winner == "player":
		_check_curio_reward()
		# Load victory reward scene for card selection
		await get_tree().create_timer(1.0).timeout  # Brief pause before transition
		SceneManager.load_scene("res://scenes/ui/victory_reward.tscn")
	else:
		# Player lost - go to game over or appropriate scene
		await get_tree().create_timer(1.0).timeout
		SceneManager.load_scene_by_name("game_over")
	
	duel_ended.emit(winner)

func _check_curio_reward():
	# Simple curio reward system - 30% chance on victory
	if randf() < 0.3:
		# For now, only Lucky Nugget is implemented
		var curio_paths = [
			"res://data/curios/common/lucky_nugget.tres"
		]
		
		var random_path = curio_paths[randi() % curio_paths.size()]
		
		# Try to load the curio resource
		if ResourceLoader.exists(random_path):
			var curio_resource = load(random_path)
			
			if curio_resource and has_node("/root/CurioManager"):
				var cm = get_node("/root/CurioManager")
				var success = cm.add_curio(curio_resource)
				
				if success:
					GLog.info("🏆 Curio Reward: You found %s!" % curio_resource.curio_name)
					GLog.info("   %s" % curio_resource.description)
					
					# Emit a reward event for UI display
					EventBus.ui_notification.emit("Found curio: %s" % curio_resource.curio_name, "reward")
				else:
					GLog.debug("Could not add curio (may be at max stacks)")
			else:
				GLog.error("CurioManager not found or curio resource invalid")
		else:
			GLog.error("Curio resource not found at: %s" % random_path)

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

func get_cards_played_this_turn() -> int:
	if duel_state and duel_state.player_data:
		return duel_state.player_data.cards_played_this_turn
	return 0

func track_player_card_for_enemy_memory(card: CardData):
	"""Track cards played by player for enemy AI adaptation"""
	var enemy = duel_state.enemy_data as EnemyState
	if enemy:
		enemy.add_to_player_memory(card.card_name)

func resolve_single_card(card_instance: CardInstance, is_player_card: bool):
	"""Immediately resolve a single card and move it to discard"""
	if not duel_state or not card_instance:
		return
	
	GLog.info("Resolving card: %s" % card_instance.get_card_name())
	
	# Remove from battlefield
	duel_state.battlefield.remove_card(card_instance)
	
	# Execute card effects - pass the CardInstance to the effects processor
	var results = card_effects_processor.apply_card_instance_effects(self, card_instance)
	
	if is_player_card:
		apply_card_results(results)
		
		# Move to player's final destination
		match card_instance.get_card_handling():
			"Standard", "Equipped", "Flash":
				duel_state.discard_pile.add_card(card_instance)
			"Hold":
				duel_state.hand.add_card(card_instance)
			"Oneshot":
				duel_state.removed_pile.add_card(card_instance)
			_:
				duel_state.discard_pile.add_card(card_instance)
		
		GLog.debug("Resolved player card: %s" % card_instance.get_card_name())
	else:
		# Enemy card
		var enemy = duel_state.enemy_data as EnemyState
		apply_enemy_card_results(results, enemy)
		
		# Move to enemy's discard - note: enemies still use CardData for now
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
		
		# For now, assume cards in player's deck are player cards
		# In the future, we may need proper card ownership tracking
		var is_player_card = _is_player_card(card_instance.card_data)
		
		if is_player_card:
			apply_card_results(results)
			
			# Move to player's final destination
			match card_instance.get_card_handling():
				"Standard", "Equipped", "Flash":
					duel_state.discard_pile.add_card(card_instance)
				"Hold":
					duel_state.hand.add_card(card_instance)
				"Oneshot":
					duel_state.removed_pile.add_card(card_instance)
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

func _is_player_card(card_data: CardData) -> bool:
	"""Determine if a card belongs to the player (simple heuristic for now)"""
	# Check if card is in player's original deck (this is a temporary solution)
	for player_card in duel_state.deck.cards:
		if player_card.card_name == card_data.card_name:
			return true
	
	for player_card in duel_state.discard_pile.cards:
		if player_card.card_name == card_data.card_name:
			return true
	
	# If not found in player piles, assume it's an enemy card
	return false

func resolve_enemy_battlefield():
	"""Enemy cards are now processed in the main resolve_battlefield() function"""
	GLog.debug("Enemy cards resolved through main battlefield resolution")
