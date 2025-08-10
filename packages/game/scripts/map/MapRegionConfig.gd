extends Resource
class_name MapRegionConfig

# Region identification
@export var region_id: String = "goldfields"
@export var region_name: String = "The Goldfields"
@export var city_name: String = "Ballarat"
@export var city_position: Vector2 = Vector2(400, 300)

# Visual theming
@export var theme_color: Color = Color.GOLD
@export var background_texture: Texture2D
@export var ambient_music_path: String = ""

# Map generation parameters
@export var region_bounds: Vector2 = Vector2(800, 600)
@export var min_nodes: int = 20
@export var max_nodes: int = 30
@export var boss_distance_from_city: float = 350.0

# Difficulty and balance
@export var difficulty_modifier: float = 1.0
@export var gold_reward_multiplier: float = 1.0
@export var enemy_health_multiplier: float = 1.0

# Node type weights for generation (relative chances)
@export var node_type_weights: Dictionary = {
	"camp": 1.0,
	"mine": 1.5,
	"settlement": 0.8,
	"poi": 1.2,
	"junction": 2.0
}

# Special properties for this region
@export var special_encounters: Array[String] = []
@export var unique_items: Array[String] = []
@export var environmental_hazards: Array[String] = []

# Boss configuration
@export var boss_name: String = "Regional Overseer"
@export var boss_enemy_id: String = "boss_generic"
@export var boss_rewards: Array[String] = []

# Lore and flavor
@export_multiline var region_description: String = ""
@export_multiline var city_description: String = ""
@export var completion_unlocks: Array[String] = []

func get_start_position() -> Vector2:
	return city_position

func get_boss_position() -> Vector2:
	# Place boss at edge of map, opposite from city
	var map_center = region_bounds / 2
	var direction_from_center = (city_position - map_center).normalized()
	# Place boss in opposite direction
	return map_center - (direction_from_center * boss_distance_from_city)

func get_random_node_type(rng: RandomNumberGenerator) -> MapNode.NodeType:
	var total_weight = 0.0
	for weight in node_type_weights.values():
		total_weight += weight
	
	var random_value = rng.randf() * total_weight
	var current_weight = 0.0
	
	if node_type_weights.has("camp"):
		current_weight += node_type_weights["camp"]
		if random_value <= current_weight:
			return MapNode.NodeType.CAMP
	
	if node_type_weights.has("mine"):
		current_weight += node_type_weights["mine"]
		if random_value <= current_weight:
			return MapNode.NodeType.MINE
	
	if node_type_weights.has("settlement"):
		current_weight += node_type_weights["settlement"]
		if random_value <= current_weight:
			return MapNode.NodeType.SETTLEMENT
	
	if node_type_weights.has("poi"):
		current_weight += node_type_weights["poi"]
		if random_value <= current_weight:
			return MapNode.NodeType.POI
	
	# Default to junction
	return MapNode.NodeType.JUNCTION

func validate_config() -> Array[String]:
	var warnings: Array[String] = []
	
	if region_id.is_empty():
		warnings.append("Region ID is empty")
	
	if city_name.is_empty():
		warnings.append("City name is empty")
	
	if region_bounds.x <= 0 or region_bounds.y <= 0:
		warnings.append("Invalid region bounds")
	
	if min_nodes > max_nodes:
		warnings.append("min_nodes is greater than max_nodes")
	
	if boss_distance_from_city <= 0:
		warnings.append("Boss distance from city must be positive")
	
	# Ensure city position is within bounds
	if city_position.x < 0 or city_position.x > region_bounds.x:
		warnings.append("City X position is outside region bounds")
	if city_position.y < 0 or city_position.y > region_bounds.y:
		warnings.append("City Y position is outside region bounds")
	
	return warnings
