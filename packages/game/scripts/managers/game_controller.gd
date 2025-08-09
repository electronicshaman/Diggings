extends Node

const DEBUG_ENABLED: bool = true

signal game_state_updated()
signal test_content_loaded()

var duel_manager: Node
var test_cards: Array[CardData] = []
var test_enemies: Array[Resource] = []
var current_duel_state: Resource
var player_character: CharacterClass

func _ready() -> void:
	GLog.debug("GameController initialized - Managing the cosmic game state")
	load_test_content()

func initialize(duel_manager_ref: Node) -> void:
	duel_manager = duel_manager_ref
	
	if duel_manager:
		duel_manager.duel_started.connect(_on_duel_started)
		duel_manager.duel_ended.connect(_on_duel_ended)
		duel_manager.turn_started.connect(_on_turn_started)
		duel_manager.card_played.connect(_on_card_played)
		
		if "duel_state" in duel_manager:
			current_duel_state = duel_manager.duel_state
			current_duel_state.add_change_listener(_on_duel_state_changed)

func load_test_content() -> void:
	GLog.debug("Loading test content...")
	load_bushranger_character()
	load_test_enemies()
	test_content_loaded.emit()

func load_bushranger_character() -> void:
	GLog.debug("Loading Bushranger character class...")
	var character_path = "res://data/characters/bushranger.tres"
	
	if ResourceLoader.exists(character_path):
		player_character = load(character_path) as CharacterClass
		if player_character:
			GLog.debug("Loaded character: " + player_character.character_class_name)
			# Load the character's starting deck
			test_cards = player_character.load_starting_deck()
			GLog.debug("Loaded %d cards for starting deck" % test_cards.size())
		else:
			GLog.error("Failed to load character resource at: " + character_path)
	else:
		GLog.error("Character resource not found: " + character_path)

func load_test_cards() -> void:
	var card_paths := [
		"res://data/cards/attack/pickaxe_strike.tres",
		"res://data/cards/attack/dynamite.tres",
		"res://data/cards/skill/bush_cover.tres",
		"res://data/cards/power/pub_brawl.tres",
		"res://data/cards/fortune/strike_it_rich.tres"
	]
	
	for path in card_paths:
		if ResourceLoader.exists(path):
			var card_data := load(path) as CardData
			if card_data:
				test_cards.append(card_data)
				GLog.debug("Loaded test card: " + card_data.card_name)
		else:
			GLog.warn("Card resource not found: " + path)

func load_test_enemies() -> void:
	var enemy_paths := [
		"res://data/enemies/claim_jumper.tres",
		"res://data/enemies/mad_dog_morgan.tres"
	]
	
	for path in enemy_paths:
		if ResourceLoader.exists(path):
			var enemy_data := load(path)
			if enemy_data:
				test_enemies.append(enemy_data)
				GLog.debug("Loaded test enemy: " + enemy_data.enemy_name)
		else:
			GLog.warn("Enemy resource not found: " + path)

func start_test_duel() -> void:
	if test_cards.is_empty() or test_enemies.is_empty() or not player_character:
		GLog.error("Cannot start duel - No test content loaded!")
		return
	
	if not duel_manager:
		GLog.error("DuelManager not initialized!")
		return
	
	# Apply character class to player data
	apply_character_to_player_data()
	
	# Use the character's starting deck (already loaded into test_cards)
	var player_deck: Array[CardData] = test_cards.duplicate()
	var enemy := test_enemies[0]
	
	GLog.debug("Starting duel as %s with enemy: %s" % [player_character.character_class_name, enemy.enemy_name])
	duel_manager.start_new_duel(player_deck, enemy)

func apply_character_to_player_data() -> void:
	if not current_duel_state or not current_duel_state.player_data or not player_character:
		GLog.error("Cannot apply character - missing player data or character")
		return
	
	var player_data = current_duel_state.player_data
	
	# Set the character class
	player_data.set_character_class(player_character)
	
	# Apply base stats from character
	if player_data.stats:
		player_data.stats.max_health = player_character.base_health
		player_data.stats.current_health = player_character.base_health
		player_data.stats.max_sanity = player_character.base_sanity
		player_data.stats.current_sanity = player_character.base_sanity
		player_data.stats.max_energy = player_character.base_energy
		player_data.stats.current_energy = player_character.base_energy
	
	GLog.debug("Applied %s stats: %d health, %d sanity, %d energy" % [
		player_character.character_class_name,
		player_character.base_health,
		player_character.base_sanity,
		player_character.base_energy
	])

func get_deck_count() -> int:
	if duel_manager and duel_manager.has_method("get_deck_count"):
		return duel_manager.get_deck_count()
	return 0

func get_discard_count() -> int:
	if duel_manager and duel_manager.has_method("get_discard_count"):
		return duel_manager.get_discard_count()
	return 0

func get_hand_cards() -> Array:
	if duel_manager and duel_manager.has_method("get_hand_cards"):
		return duel_manager.get_hand_cards()
	return []

func play_card(card_data: CardData) -> void:
	if duel_manager and duel_manager.has_method("play_card"):
		duel_manager.play_card(card_data)

func end_player_turn() -> void:
	if duel_manager and current_duel_state:
		if current_duel_state.is_player_turn:
			duel_manager.end_player_turn()

func add_random_card_to_hand() -> void:
	if test_cards.is_empty() or not current_duel_state:
		return
	
	var random_card := test_cards[randi() % test_cards.size()]
	current_duel_state.hand.add_card(random_card)
	game_state_updated.emit()

func modify_player_health(amount: int) -> void:
	if current_duel_state and current_duel_state.player_data:
		current_duel_state.player_data.current_health += amount
		current_duel_state.player_data.current_health = clampi(
			current_duel_state.player_data.current_health,
			0,
			current_duel_state.player_data.max_health
		)
		game_state_updated.emit()

func modify_player_energy(amount: int) -> void:
	if current_duel_state and current_duel_state.player_data:
		current_duel_state.player_data.current_energy += amount
		current_duel_state.player_data.current_energy = clampi(
			current_duel_state.player_data.current_energy,
			0,
			current_duel_state.player_data.max_energy
		)
		game_state_updated.emit()

func _on_duel_started() -> void:
	GLog.debug("Duel started in GameController")
	game_state_updated.emit()
	EventBus.duel_started.emit(current_duel_state.enemy_data if current_duel_state else null)

func _on_duel_ended(winner: String) -> void:
	GLog.debug("Duel ended - Winner: " + winner)
	var victory := winner == "player"
	EventBus.duel_ended.emit(victory)
	GameManager.increment_statistic("enemies_defeated" if victory else "defeats")

func _on_turn_started(is_player_turn: bool) -> void:
	GLog.debug("Turn started: " + ("Player" if is_player_turn else "Enemy"))
	if current_duel_state:
		EventBus.turn_started.emit(current_duel_state.current_turn)
	game_state_updated.emit()

func _on_card_played(card_data: CardData) -> void:
	GLog.debug("Card played: " + card_data.card_name)
	GameManager.increment_statistic("cards_played")
	game_state_updated.emit()

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	game_state_updated.emit()
	if change_type == "damage_dealt":
		GameManager.increment_statistic("damage_dealt", _data.get("amount", 0))
