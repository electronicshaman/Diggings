class_name DuelIntent
extends SceneIntent

## Intent for starting a duel scene.
## Wraps DuelConfig with additional routing information.

## The duel configuration (deck, enemy, modifiers)
var config: DuelConfig = null

## Whether this is a test duel (affects post-duel routing)
var is_test_duel: bool = false

## Whether to show rewards after victory
var show_rewards: bool = true

## For test sequences: continue to next battle after rewards
var is_sequence_battle: bool = false

func _init(p_config: DuelConfig, p_return_scene: String = "map") -> void:
	super (p_return_scene)
	config = p_config

func get_intent_type() -> String:
	return "DuelIntent"

## Check if the underlying config is valid
func is_valid() -> bool:
	return config != null and config.is_valid()

## Factory for test duels
static func create_test_duel(p_config: DuelConfig, p_show_rewards: bool = false) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "test_duel_setup")
	intent.is_test_duel = true
	intent.show_rewards = p_show_rewards
	return intent

## Factory for sequence battles
static func create_sequence_battle(p_config: DuelConfig, p_show_rewards: bool = true) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "test_duel_setup")
	intent.is_test_duel = true
	intent.is_sequence_battle = true
	intent.show_rewards = p_show_rewards
	return intent

## Factory for normal gameplay duels
static func create_gameplay_duel(p_config: DuelConfig) -> DuelIntent:
	var intent = DuelIntent.new(p_config, "map")
	intent.is_test_duel = false
	intent.show_rewards = true
	return intent
