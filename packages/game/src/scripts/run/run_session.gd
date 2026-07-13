extends RefCounted
class_name RunSession

enum State { INACTIVE, FIGHT_READY, IN_DUEL, REWARD_PENDING, COMPLETED, DEFEATED }
enum EndReason { NONE, HEALTH, SANITY, INVALID_STATE }

var state: State = State.INACTIVE
var definition: RunDefinition
var character: CharacterClass
var seed: int
var fight_index: int = 0
var fights_won: int = 0
var player_snapshot: RunPlayerSnapshot
var pending_card_offers: Array[CardData] = []
var cards_added: Array[String] = []
var end_reason: EndReason = EndReason.NONE

var _deck_manager: Object
var _seed_manager: Node
var _candidates: Array[CardData] = []


func _init(deck_manager: Object, seed_manager: Node) -> void:
	_deck_manager = deck_manager
	_seed_manager = seed_manager


func begin(run_definition: RunDefinition, selected_character: CharacterClass, run_seed: int) -> bool:
	if state != State.INACTIVE or not run_definition or not run_definition.is_valid() or not selected_character:
		return false
	if not _deck_manager.is_deck_available():
		return false
	if _seed_manager.get_master_seed() == run_seed and not _seed_manager.get_hash_seed_string().is_empty():
		_seed_manager.setup_subsystem_seeds()
	else:
		_seed_manager.set_master_seed(run_seed)
	definition = run_definition
	character = selected_character
	seed = run_seed
	fight_index = 0
	fights_won = 0
	cards_added.clear()
	pending_card_offers.clear()
	var player := PlayerData.new()
	player.set_character_class(character)
	player.stats.max_health = character.base_health
	player.stats.current_health = character.base_health
	player.stats.max_sanity = character.base_sanity
	player.stats.current_sanity = character.base_sanity
	player.stats.max_energy = character.base_energy
	player.stats.current_energy = character.base_energy
	player.stats.current_gold = character.starting_gold
	player_snapshot = RunPlayerSnapshot.capture(player)
	_candidates = RewardOfferGenerator.load_candidates("res://data/cards/player")
	state = State.FIGHT_READY
	return true


func prepare_current_duel() -> DuelConfig:
	if state != State.FIGHT_READY or fight_index >= definition.enemies.size():
		return null
	var config := DuelConfig.new(
		_deck_manager.get_current_deck(),
		definition.enemies[fight_index].duplicate(true),
		"curated_run",
		{
			"curated_run": true,
			"player_data": player_snapshot.to_player_data(),
			"character_class": character
		}
	)
	if not config.is_valid():
		return null
	state = State.IN_DUEL
	return config


func record_victory(player: PlayerData) -> bool:
	if state != State.IN_DUEL:
		return false
	var captured := RunPlayerSnapshot.capture(player)
	if not _is_valid_victory_snapshot(captured):
		record_defeat(EndReason.INVALID_STATE)
		return false
	player_snapshot = captured
	fights_won += 1
	if fight_index == definition.enemies.size() - 1:
		state = State.COMPLETED
		return true
	pending_card_offers = RewardOfferGenerator.generate(
		character,
		_candidates,
		definition.card_offer_count,
		_seed_manager.loot_rng
	)
	state = State.REWARD_PENDING
	return true


func _is_valid_victory_snapshot(snapshot: RunPlayerSnapshot) -> bool:
	return (
		is_instance_valid(snapshot)
		and is_instance_valid(snapshot.character_class)
		and snapshot.character_class == character
		and snapshot.health > 0
		and snapshot.sanity > 0
	)


func get_pending_card_offers() -> Array[CardData]:
	return pending_card_offers.duplicate() if state == State.REWARD_PENDING else []


func apply_card_reward(card: CardData) -> bool:
	if state != State.REWARD_PENDING or not is_instance_valid(card):
		return false
	var valid_offer := false
	for offered in pending_card_offers:
		if offered.resource_path == card.resource_path:
			valid_offer = true
			break
	if not valid_offer or not _deck_manager.add_card(card):
		return false
	cards_added.append(card.card_name)
	_advance_after_reward()
	return true


func apply_recovery() -> bool:
	if state != State.REWARD_PENDING:
		return false
	player_snapshot.health = mini(
		player_snapshot.max_health,
		player_snapshot.health + definition.recovery_health
	)
	player_snapshot.sanity = mini(
		player_snapshot.max_sanity,
		player_snapshot.sanity + definition.recovery_sanity
	)
	_advance_after_reward()
	return true


func _advance_after_reward() -> void:
	pending_card_offers.clear()
	fight_index += 1
	state = State.FIGHT_READY


func record_defeat(reason: EndReason) -> void:
	if state in [State.COMPLETED, State.DEFEATED, State.INACTIVE]:
		return
	end_reason = EndReason.INVALID_STATE if reason == EndReason.NONE else reason
	state = State.DEFEATED


func is_complete() -> bool:
	return state == State.COMPLETED


func get_summary() -> Dictionary:
	return {
		"character_class": character.character_class_name if character else "Unknown",
		"seed": seed,
		"fights_won": fights_won,
		"final_health": player_snapshot.health if player_snapshot else 0,
		"final_sanity": player_snapshot.sanity if player_snapshot else 0,
		"cards_added": cards_added.duplicate(),
		"victory": state == State.COMPLETED,
		"end_reason": end_reason
	}
