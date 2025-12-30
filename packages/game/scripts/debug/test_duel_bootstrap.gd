extends Node

## TestDuelBootstrap
# Attaching this node in the debug scene will auto-start a duel for testing.
# Keeps production duel scene free of bootstrapping.

func _ready() -> void:
	await get_tree().process_frame
	var root := get_parent()
	if not is_instance_valid(root):
		push_warning("TestDuelBootstrap: Root not valid")
		return
	
	# Find GameController anywhere under the root (supports nested Duel instance)
	var game_controller = root.get_node_or_null("GameController")
	if not is_instance_valid(game_controller):
		game_controller = root.get_node_or_null("Duel/GameController")
	if not is_instance_valid(game_controller):
		game_controller = root.find_child("GameController", true, false)
	
	if not is_instance_valid(game_controller):
		push_warning("TestDuelBootstrap: GameController not found")
		return
	
	# Load GameEffect test deck
	var test_deck_path = "res://data/decks/test/gameeffect_test.tres"
	var deck_data = load(test_deck_path) as DeckData
	if not deck_data:
		push_error("TestDuelBootstrap: Failed to load GameEffect test deck")
		return
	
	# Load default enemy
	var enemy_path = "res://data/enemies/claim_jumper.tres"
	var enemy_data = load(enemy_path)
	if not enemy_data:
		push_error("TestDuelBootstrap: Failed to load enemy")
		return
	
	# Debug enemy health
	if enemy_data.stats:
		print("TestDuelBootstrap: Enemy loaded with HP: %d/%d" % [enemy_data.stats.current_health, enemy_data.stats.max_health])
	else:
		print("TestDuelBootstrap: Enemy has no stats!")
	
	# Start test duel with GameEffect cards only
	print("TestDuelBootstrap: Starting test duel with %d GameEffect cards" % deck_data.card_paths.size())
	if game_controller.has_method("start_duel"):
		game_controller.start_duel(deck_data, enemy_data)
	else:
		push_warning("TestDuelBootstrap: GameController missing start_duel method")
