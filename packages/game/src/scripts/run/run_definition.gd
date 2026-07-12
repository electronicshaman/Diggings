extends Resource
class_name RunDefinition

@export var run_id: StringName
@export var display_name: String
@export var enemies: Array[Resource] = []
@export_range(0, 100) var recovery_health: int = 12
@export_range(0, 100) var recovery_sanity: int = 4
@export_range(1, 5) var card_offer_count: int = 3

func is_valid() -> bool:
	return get_validation_errors().is_empty()

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if run_id.is_empty():
		errors.append("Run ID is empty")
	if display_name.strip_edges().is_empty():
		errors.append("Display name is empty")
	if enemies.size() != 3:
		errors.append("Run must contain exactly 3 enemies")
	for index in range(enemies.size()):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			errors.append("Enemy %d is invalid" % (index + 1))
			continue
		var manager = enemy.get("card_manager")
		if not is_instance_valid(manager) or not is_instance_valid(manager.get("deck_data")):
			errors.append("Enemy %d has no valid deck" % (index + 1))
	if recovery_health < 0:
		errors.append("Recovery health cannot be negative")
	if recovery_sanity < 0:
		errors.append("Recovery sanity cannot be negative")
	if card_offer_count <= 0:
		errors.append("Card offer count must be positive")
	return errors
