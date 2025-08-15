extends CardEffect
class_name CoinFlip

const EFFECT_NAME := "Coin Flip"

# Coin Flip Effect - Multiple coin flips with escalating rewards
# Used for Miner's Luck and similar multi-outcome fortune cards

@export var flip_count: int = 3  # Number of coins to flip
@export var heads_chance: float = 0.5  # Chance for heads (0.5 = 50/50)

# Rewards based on number of heads
@export var reward_1_heads: Dictionary = {"type": "draw", "value": 1}  # 1 heads = Draw 1
@export var reward_2_heads: Dictionary = {"type": "gold", "value": 8}  # 2 heads = Gain 8 Gold
@export var reward_3_heads: Dictionary = {"type": "damage", "value": 12}  # 3 heads = Deal 12 damage
@export var reward_0_heads: Dictionary = {}  # No heads = no effect by default

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add coin flip to results
	if not results.has("coin_flip"):
		results.coin_flip = []
	
	var rewards: Array = []
	if not reward_0_heads.is_empty():
		rewards.append({"heads_required": 0, "reward": reward_0_heads})
	if not reward_1_heads.is_empty():
		rewards.append({"heads_required": 1, "reward": reward_1_heads})
	if not reward_2_heads.is_empty():
		rewards.append({"heads_required": 2, "reward": reward_2_heads})
	if not reward_3_heads.is_empty():
		rewards.append({"heads_required": 3, "reward": reward_3_heads})
	
	results.coin_flip.append({
		"flip_count": flip_count,
		"heads_chance": heads_chance,
		"rewards": rewards
	})
	
	print("Applied %s effect from %s (flip %d coins)" % [
		get_effect_name(), 
		card_data.card_name, 
		flip_count
	])

func get_formatted_description() -> String:
	var desc: String = "Flip %d coins. " % flip_count
	var rewards_text: Array = []
	
	if not reward_0_heads.is_empty():
		rewards_text.append("0 heads: %s" % _format_reward(reward_0_heads))
	if not reward_1_heads.is_empty():
		rewards_text.append("1 heads: %s" % _format_reward(reward_1_heads))
	if not reward_2_heads.is_empty():
		rewards_text.append("2 heads: %s" % _format_reward(reward_2_heads))
	if not reward_3_heads.is_empty():
		rewards_text.append("3 heads: %s" % _format_reward(reward_3_heads))
	
	desc += ", ".join(rewards_text)
	return desc

func _format_reward(reward: Dictionary) -> String:
	if not reward.has("type") or not reward.has("value"):
		return "No effect"
	
	match reward.type:
		"damage":
			return "Deal %d damage" % reward.value
		"gold":
			return "Gain %d Gold" % reward.value
		"draw":
			if reward.value == 1:
				return "Draw 1 card"
			else:
				return "Draw %d cards" % reward.value
		"block":
			return "Gain %d Block" % reward.value
		"heal":
			return "Heal %d Health" % reward.value
		"energy":
			return "Gain %d Energy" % reward.value
		_:
			return "Special effect"

func get_effect_name() -> String:
	return EFFECT_NAME