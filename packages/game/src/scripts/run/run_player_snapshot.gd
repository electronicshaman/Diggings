extends Resource
class_name RunPlayerSnapshot

@export var character_class: CharacterClass
@export var health: int
@export var max_health: int
@export var sanity: int
@export var max_sanity: int
@export var max_energy: int
@export var gold: int
@export var custom_resources: Dictionary = {}
@export var custom_resource_max: Dictionary = {}
@export var run_corruption: int
@export var corruption_triggered_tiers: Dictionary = {}

static func capture(player: PlayerData) -> RunPlayerSnapshot:
	if not is_instance_valid(player) or not is_instance_valid(player.stats):
		return null
	var snapshot := RunPlayerSnapshot.new()
	snapshot.character_class = player.character_class
	snapshot.health = player.stats.current_health
	snapshot.max_health = player.stats.max_health
	snapshot.sanity = player.stats.current_sanity
	snapshot.max_sanity = player.stats.max_sanity
	snapshot.max_energy = player.stats.max_energy
	snapshot.gold = player.stats.current_gold
	snapshot.custom_resources = player.custom_resources.duplicate(true)
	snapshot.custom_resource_max = player.custom_resource_max.duplicate(true)
	snapshot.run_corruption = player.run_corruption
	snapshot.corruption_triggered_tiers = player.corruption_triggered_tiers.duplicate(true)
	return snapshot

func to_player_data() -> PlayerData:
	var player := PlayerData.new()
	player.set_character_class(character_class)
	player.stats.max_health = max_health
	player.stats.current_health = health
	player.stats.max_sanity = max_sanity
	player.stats.current_sanity = sanity
	player.stats.max_energy = max_energy
	player.stats.current_energy = max_energy
	player.stats.defense = 0
	player.stats.current_gold = gold
	player.custom_resources = custom_resources.duplicate(true)
	player.custom_resource_max = custom_resource_max.duplicate(true)
	player.run_corruption = run_corruption
	player.corruption_triggered_tiers = corruption_triggered_tiers.duplicate(true)
	return player
