class_name AnimationController
extends Node

## AnimationController - Manages combat animations and timing
##
## Centralizes all animation timing and visual feedback for the duel system.
## Separates visual concerns from game logic.

const DEBUG_ENABLED: bool = true

# Timing configuration (can be overridden by GameSettings)
var card_stage_delay: float = 0.5 # Time card sits on battlefield before resolving
var enemy_card_play_delay: float = 1.5 # Time between enemy card plays
var enemy_turn_start_delay: float = 1.0 # Delay before enemy starts
var turn_transition_delay: float = 0.6 # Delay between turns
var card_draw_delay: float = 0.3 # Time for card draw animation
var damage_number_duration: float = 1.0 # Time damage numbers are visible
var effect_resolve_delay: float = 0.4 # Time between effect resolutions

signal animation_started(animation_name: String)
signal animation_completed(animation_name: String)
signal all_animations_completed()

var active_animations: Array[String] = []
var animation_queue: Array[Dictionary] = []
var is_processing_queue: bool = false

func _ready() -> void:
	GLog.debug("AnimationController initialized")
	_load_timing_from_settings()

## Load timing values from GameSettings if available
func _load_timing_from_settings() -> void:
	if not is_instance_valid(GameSettings):
		return
	
	# Override with settings if they exist
	if GameSettings.has_method("get_animation_timing"):
		var timing = GameSettings.get_animation_timing()
		if timing.has("card_stage_delay"):
			card_stage_delay = timing.card_stage_delay
		if timing.has("enemy_card_play_delay"):
			enemy_card_play_delay = timing.enemy_card_play_delay
		if timing.has("enemy_turn_start_delay"):
			enemy_turn_start_delay = timing.enemy_turn_start_delay
		if timing.has("turn_transition_delay"):
			turn_transition_delay = timing.turn_transition_delay

## Queue an animation with optional callback
func queue_animation(animation_name: String, duration: float, callback: Callable = Callable()) -> void:
	animation_queue.append({
		"name": animation_name,
		"duration": duration,
		"callback": callback
	})
	
	if not is_processing_queue:
		_process_animation_queue()

## Process queued animations sequentially
func _process_animation_queue() -> void:
	if animation_queue.is_empty():
		is_processing_queue = false
		all_animations_completed.emit()
		return
	
	is_processing_queue = true
	var animation = animation_queue.pop_front()
	
	await play_animation(animation.name, animation.duration, animation.callback)
	
	# Continue processing queue
	_process_animation_queue()

## Play an animation with a duration and optional callback
func play_animation(animation_name: String, duration: float, callback: Callable = Callable()) -> void:
	active_animations.append(animation_name)
	animation_started.emit(animation_name)
	
	GLog.debug("Animation started: %s (%.2fs)" % [animation_name, duration])
	
	await get_tree().create_timer(duration).timeout
	
	active_animations.erase(animation_name)
	animation_completed.emit(animation_name)
	
	if callback.is_valid():
		callback.call()

## Wait for a specific delay
func wait(delay: float) -> void:
	await get_tree().create_timer(delay).timeout

## Play card staging animation
func play_card_staging(card_name: String) -> void:
	await play_animation("card_stage_" + card_name, card_stage_delay)

## Play enemy card animation
func play_enemy_card(card_name: String) -> void:
	await play_animation("enemy_play_" + card_name, enemy_card_play_delay)

## Play turn start animation
func play_turn_start(is_player: bool) -> void:
	var turn_type = "player" if is_player else "enemy"
	var delay = 0.3 if is_player else enemy_turn_start_delay
	await play_animation("turn_start_" + turn_type, delay)

## Play turn end animation
func play_turn_end(is_player: bool) -> void:
	var turn_type = "player" if is_player else "enemy"
	await play_animation("turn_end_" + turn_type, turn_transition_delay)

## Play card draw animation
func play_card_draw(count: int = 1) -> void:
	for i in count:
		await play_animation("card_draw", card_draw_delay)

## Play damage animation
func play_damage(target: String, amount: int) -> void:
	await play_animation("damage_" + target + "_" + str(amount), damage_number_duration)

## Play healing animation
func play_healing(target: String, amount: int) -> void:
	await play_animation("heal_" + target + "_" + str(amount), damage_number_duration)

## Play shield/defense animation
func play_defense(target: String, amount: int) -> void:
	await play_animation("defense_" + target + "_" + str(amount), effect_resolve_delay)

## Play effect resolution
func play_effect(effect_name: String) -> void:
	await play_animation("effect_" + effect_name, effect_resolve_delay)

## Check if any animations are active
func is_animating() -> bool:
	return active_animations.size() > 0 or is_processing_queue

## Skip all current animations (for testing/quick play)
func skip_all_animations() -> void:
	active_animations.clear()
	animation_queue.clear()
	is_processing_queue = false
	GLog.debug("All animations skipped")

## Get current animation speed multiplier
func get_speed_multiplier() -> float:
	if GameSettings and GameSettings.has_method("get_animation_speed"):
		return GameSettings.get_animation_speed()
	return 1.0

## Apply speed multiplier to a duration
func apply_speed(duration: float) -> float:
	return duration / get_speed_multiplier()