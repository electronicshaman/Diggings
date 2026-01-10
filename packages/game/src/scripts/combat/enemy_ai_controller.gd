## EnemyAIController
## Handles AI decision-making and card selection based on AI personality types.
## Follows Strategy pattern for different AI behaviors.
extends RefCounted
class_name EnemyAIController

# Constants
const MAX_CARDS_PER_TURN: int = 3
const ENEMY_CARD_PLAY_DELAY: float = 1.5 # Time between enemy card plays
const LOW_HEALTH_THRESHOLD: float = 0.3 # Used for defensive/aggressive decisions

# Dependencies
var duel_state: DuelState


func _init(state: DuelState) -> void:
	duel_state = state
	GLog.debug("EnemyAIController initialized", "enemy_ai_controller")


## Card Selection Methods

func get_playable_cards(enemy: EnemyState) -> Array[CardData]:
	"""Get cards the enemy can afford to play based on energy cost"""
	var playable: Array[CardData] = []
	var current_energy := enemy.stats.current_energy if enemy.stats else 0
	
	for inst in enemy.enemy_hand.cards:
		var cd: CardData = inst.card_data if inst else null
		if cd and cd.energy_cost <= current_energy:
			playable.append(cd)
	
	GLog.debug("Found %d playable cards with %d energy" % [playable.size(), current_energy], "enemy_ai_controller")
	return playable


func select_card(enemy: EnemyState, playable: Array[CardData]) -> CardData:
	"""Select which card to play based on AI type"""
	if playable.is_empty():
		return null
	
	match enemy.ai_type:
		GameEnums.AIType.AGGRESSIVE:
			return _select_aggressive(playable)
		GameEnums.AIType.DEFENSIVE:
			return _select_defensive(playable)
		GameEnums.AIType.BALANCED:
			return _select_balanced(enemy, playable)
		GameEnums.AIType.CUNNING:
			return _select_cunning(enemy, playable)
		_:
			GLog.warn("Unknown AI type '%s', using default" % enemy.ai_type, "enemy_ai_controller")
			return playable[0] # Fallback to first card


func execute_turn(enemy: EnemyState, card_resolver: RefCounted) -> void:
	"""Execute the enemy's turn by playing cards"""
	GLog.info("Enemy AI (Type: %d) is taking its turn" % enemy.ai_type, "enemy_ai_controller")
	
	var cards_played := 0
	
	# Get playable cards based on energy
	var playable_cards := get_playable_cards(enemy)
	
	while playable_cards.size() > 0 and cards_played < MAX_CARDS_PER_TURN:
		var card_to_play := select_card(enemy, playable_cards)
		
		if card_to_play:
			# Use the card resolver to play the enemy card (now properly async)
			await card_resolver.play_enemy_card(enemy, card_to_play)
			cards_played += 1
			
			# Add delay between card plays for readability
			if cards_played < MAX_CARDS_PER_TURN:
				await Engine.get_main_loop().create_timer(ENEMY_CARD_PLAY_DELAY).timeout
			
			# Update playable cards after spending energy
			playable_cards = get_playable_cards(enemy)
		else:
			break
	
	if cards_played == 0:
		GLog.info("Enemy couldn't play any cards this turn", "enemy_ai_controller")
	else:
		GLog.info("Enemy played %d cards this turn" % cards_played, "enemy_ai_controller")


## AI Type Implementations

func _select_aggressive(playable: Array[CardData]) -> CardData:
	"""Prioritize Attack cards"""
	# First, try to find Attack cards
	for card in playable:
		if card.card_type == "Attack":
			GLog.debug("Aggressive AI selected Attack card: %s" % card.card_name, "enemy_ai_controller")
			return card
	
	# Fall back to any card if no Attack cards available
	GLog.debug("Aggressive AI: No Attack cards, selecting first available: %s" % playable[0].card_name, "enemy_ai_controller")
	return playable[0]


func _select_defensive(playable: Array[CardData]) -> CardData:
	"""Prioritize Skill cards and low cost options"""
	# First, try to find Skill cards
	for card in playable:
		if card.card_type == "Skill":
			GLog.debug("Defensive AI selected Skill card: %s" % card.card_name, "enemy_ai_controller")
			return card
	
	# Fall back to cheapest card
	var cheapest := playable[0]
	for card in playable:
		if card.energy_cost < cheapest.energy_cost:
			cheapest = card
	
	GLog.debug("Defensive AI: No Skill cards, selecting cheapest: %s (cost: %d)" % [cheapest.card_name, cheapest.energy_cost], "enemy_ai_controller")
	return cheapest


func _select_balanced(enemy: EnemyState, playable: Array[CardData]) -> CardData:
	"""Adapt based on health ratios of both combatants"""
	var player_health_ratio := 1.0
	if duel_state and duel_state.player_data and duel_state.player_data.stats:
		player_health_ratio = duel_state.player_data.stats.get_health_percentage()
	
	var enemy_health_ratio := 1.0
	if enemy.stats:
		enemy_health_ratio = enemy.stats.get_health_percentage()
	
	if enemy_health_ratio < LOW_HEALTH_THRESHOLD:
		# Low health, play defensively - prioritize Skill cards
		for card in playable:
			if card.card_type == "Skill":
				GLog.debug("Balanced AI (defensive): Selected Skill card: %s" % card.card_name, "enemy_ai_controller")
				return card
	elif player_health_ratio < LOW_HEALTH_THRESHOLD:
		# Player low health, be aggressive - prioritize Attack cards
		for card in playable:
			if card.card_type == "Attack":
				GLog.debug("Balanced AI (aggressive): Selected Attack card: %s" % card.card_name, "enemy_ai_controller")
				return card
	
	# Default: play highest cost card we can afford
	var best := playable[0]
	for card in playable:
		if card.energy_cost > best.energy_cost:
			best = card
	
	GLog.debug("Balanced AI (default): Selected highest cost card: %s (cost: %d)" % [best.card_name, best.energy_cost], "enemy_ai_controller")
	return best


func _select_cunning(enemy: EnemyState, playable: Array[CardData]) -> CardData:
	"""Counter player patterns using card memory"""
	var most_played := enemy.get_player_most_played_card()
	
	# Try to counter common player patterns
	if "Strike" in most_played or "Attack" in most_played:
		# Player plays lots of attacks, prioritize defense
		for card in playable:
			if card.card_type == "Skill":
				GLog.debug("Cunning AI (counter-attack): Selected Skill card: %s" % card.card_name, "enemy_ai_controller")
				return card
	elif "Block" in most_played or "Defend" in most_played:
		# Player plays defensively, be aggressive
		for card in playable:
			if card.card_type == "Attack":
				GLog.debug("Cunning AI (counter-defense): Selected Attack card: %s" % card.card_name, "enemy_ai_controller")
				return card
	
	# Default: random selection for unpredictability
	var selected := playable[randi() % playable.size()]
	GLog.debug("Cunning AI (random): Selected card: %s" % selected.card_name, "enemy_ai_controller")
	return selected