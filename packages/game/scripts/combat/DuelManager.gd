extends Node
class_name DuelManager

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED = true

@export var duel_state: DuelState
@export var initial_hand_size: int = 5
@export var cards_per_turn_draw: int = 1

signal duel_started
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)
signal card_played(card: CardData)
signal duel_ended(winner: String)

var card_effects_processor: CardEffects

func _ready():
	GLog.info("DuelManager initializing...")
	
	if not duel_state:
		duel_state = DuelState.new()
		GLog.info("Created new DuelState")
	
	card_effects_processor = CardEffects.new()
	
	duel_state.add_change_listener(_on_duel_state_changed)

func _on_duel_state_changed(change_type: String, data: Dictionary):
	GLog.debug("DuelState changed: %s" % change_type)
	
	match change_type:
		"player_died", "player_went_insane":
			end_duel("enemy")
		"enemy_died":
			end_duel("player")

func start_new_duel(player_deck: Array[CardData], enemy_data: EnemyState):
	GLog.info("Starting new duel...")
	
	duel_state.enemy_data = enemy_data
	
	duel_state.deck.clear()
	duel_state.discard_pile.clear()
	duel_state.hand.clear()
	duel_state.removed_pile.clear()
	
	for card in player_deck:
		duel_state.deck.add_card(card)
	
	duel_state.deck.shuffle()
	
	duel_state.start_duel()
	
	draw_initial_hand()
	
	duel_started.emit()
	
	start_player_turn()

func draw_initial_hand():
	var drawn = duel_state.draw_cards(initial_hand_size)
	GLog.info("Drew initial hand of %d cards" % drawn.size())

func start_player_turn():
	GLog.info("Starting player turn %d" % (duel_state.player_turn_count + 1))
	
	duel_state.start_player_turn()
	
	if duel_state.player_turn_count > 1:
		var drawn = duel_state.draw_cards(cards_per_turn_draw)
		if drawn.size() > 0:
			GLog.debug("Drew %d card(s) for turn" % drawn.size())
	
	turn_started.emit(true)

func end_player_turn():
	GLog.debug("Ending player turn")
	
	duel_state.end_player_turn()
	turn_ended.emit(true)
	
	if not duel_state.is_duel_over():
		start_enemy_turn()

func start_enemy_turn():
	GLog.info("Starting enemy turn %d" % (duel_state.enemy_turn_count + 1))
	
	duel_state.start_enemy_turn()
	turn_started.emit(false)
	
	process_enemy_turn()

func process_enemy_turn():
	var enemy = duel_state.enemy_data
	
	if enemy.is_stunned():
		GLog.debug("Enemy is stunned, skipping turn")
		enemy.reduce_stun()
		end_enemy_turn()
		return
	
	var damage = 5 + (enemy.turns_alive * 2)
	GLog.info("Enemy attacks for %d damage!" % damage)
	
	var actual_damage = duel_state.player_data.take_damage(damage)
	GLog.info("Player took %d damage (after cover)" % actual_damage)
	
	end_enemy_turn()

func end_enemy_turn():
	GLog.debug("Ending enemy turn")
	
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

func play_card(card_data: CardData):
	if not can_play_card(card_data):
		GLog.warn("Cannot play card: %s" % card_data.card_name)
		return
	
	GLog.info("Playing card: %s" % card_data.card_name)
	
	var player = duel_state.player_data
	var actual_cost = player.get_actual_energy_cost(card_data.energy_cost, card_data.card_type)
	
	player.pay_energy(actual_cost)
	player.pay_sanity(card_data.sanity_cost)
	
	var results = card_effects_processor.apply_card_effects(self, card_data)
	
	apply_card_results(results)
	
	player.apply_card_cost_reductions()
	player.cards_played_this_turn += 1
	
	duel_state.play_card(card_data)
	
	card_played.emit(card_data)
	
	if duel_state.is_duel_over():
		var winner = duel_state.get_winner()
		end_duel(winner)

func apply_card_results(results: Dictionary):
	var player = duel_state.player_data
	var enemy = duel_state.enemy_data
	
	if results.has("damage") and results.damage > 0:
		var ignore_cover = results.get("ignores_cover", false)
		var actual_damage = enemy.take_damage(results.damage, ignore_cover)
		player.damage_dealt_this_turn += actual_damage
		GLog.info("Dealt %d damage to enemy" % actual_damage)
	
	if results.has("defense") and results.defense > 0:
		player.gain_cover(results.defense)
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

func end_duel(winner: String):
	GLog.info("Duel ended! Winner: %s" % winner)
	duel_state.end_duel(winner)
	duel_ended.emit(winner)

func get_hand_cards() -> Array[CardData]:
	return duel_state.hand.cards if duel_state.hand else []

func get_deck_count() -> int:
	return duel_state.deck.size() if duel_state.deck else 0

func get_discard_count() -> int:
	return duel_state.discard_pile.size() if duel_state.discard_pile else 0
