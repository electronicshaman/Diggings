class_name DuelIntent
extends SceneIntent

## Intent for starting a duel scene.
## Wraps DuelConfig with additional routing information.

## The duel configuration (deck, enemy, modifiers)
var config: DuelConfig = null

## Whether this is a quick duel (affects post-duel routing)
var is_quick_duel: bool = false

## Whether to show rewards after victory
var show_rewards: bool = true

## For duel sequences: continue to next battle after rewards
var is_sequence_battle: bool = false

func _init(p_config: DuelConfig, p_return_scene: String = "map") -> void:
	super (p_return_scene)
	config = p_config

func get_intent_type() -> String:
	return "DuelIntent"

## Check if the underlying config is valid
func is_valid() -> bool:
	return config != null and config.is_valid()

## Factory for quick duels
static func create_quick_duel(p_config: DuelConfig, p_show_rewards: bool = false) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "quick_duel_setup")
	intent.is_quick_duel = true
	intent.show_rewards = p_show_rewards
	return intent

## Factory for sequence battles
static func create_sequence_battle(p_config: DuelConfig, p_show_rewards: bool = true) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "quick_duel_setup")
	intent.is_quick_duel = true
	intent.is_sequence_battle = true
	intent.show_rewards = p_show_rewards
	return intent

## Factory for normal gameplay duels
static func create_gameplay_duel(p_config: DuelConfig) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "map")
	intent.is_quick_duel = false
	intent.show_rewards = true
	return intent
