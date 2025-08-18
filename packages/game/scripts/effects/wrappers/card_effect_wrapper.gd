extends Resource
class_name CardEffectWrapper

@export var base_effect: Resource # GameEffect
@export var energy_cost_modifier: int = 0
@export var exhaust_on_use: bool = false
@export var card_specific_conditions: Dictionary = {}
