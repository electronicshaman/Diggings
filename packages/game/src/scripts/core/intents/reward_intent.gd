class_name RewardIntent
extends SceneIntent

## Intent for the victory/reward scene.
## Defines what mode the reward screen operates in and where to go after.

## Should continue to next battle in a sequence
var continue_sequence: bool = false

## Specific cards to offer (empty = random from pool)
var offered_cards: Array[CardData] = []

## Gold reward amount (0 = calculate from enemy)
var gold_reward: int = 0

## Whether to offer curio selection after card
var offer_curio: bool = false

func _init(p_return_scene: String = "map") -> void:
	super (p_return_scene)

func get_intent_type() -> String:
	return "RewardIntent"

## Factory for quick duel sequence rewards
static func create_quick_duel_reward(p_continue_sequence: bool, p_return_scene: String = "quick_duel_setup") -> RewardIntent:
	var intent = RewardIntent.new(p_return_scene)
	intent.continue_sequence = p_continue_sequence
	return intent

## Factory for normal post-duel rewards
static func create_victory_reward(p_offer_curio: bool = false) -> RewardIntent:
	var intent = RewardIntent.new("map")
	intent.offer_curio = p_offer_curio
	return intent
