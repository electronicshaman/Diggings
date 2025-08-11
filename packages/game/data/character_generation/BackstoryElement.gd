extends Resource
class_name BackstoryElement

@export var element_id: String = ""
@export var element_type: String = "origin"
@export var display_name: String = ""
@export var description: String = ""
@export var flavor_text: String = ""
@export var weight: float = 10.0
@export var class_compatibility: Dictionary = {}
@export var stat_modifiers: Dictionary = {}
@export var percentage_modifiers: Dictionary = {}
@export var special_modifiers: Dictionary = {}
@export var gameplay_rules: Array[String] = []
@export var conditional_modifiers: Array = []
@export var compatible_next_elements: Array[String] = []
@export var incompatible_elements: Array[String] = []
@export var required_elements: Array[String] = []
@export var adds_objective: bool = false
@export var objective_type: String = ""
@export var objective_value: int = 0
@export var objective_reward: String = ""
@export var icon: Texture2D
@export var color_theme: Color = Color.WHITE
@export var nickname_pool: Array[String] = []