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
	if is_instance_valid(game_controller) and game_controller.has_method("start_test_duel"):
		game_controller.start_test_duel()
	else:
		push_warning("TestDuelBootstrap: GameController missing or no start_test_duel()")
