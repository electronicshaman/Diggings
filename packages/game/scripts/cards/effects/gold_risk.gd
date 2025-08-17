extends CardEffect
class_name GoldRisk

const EFFECT_NAME := "Gold Risk"

# Gold Risk Effect - Risk gold for potential reward
# Used for Double or Nothing and similar high-risk fortune cards

@export var risk_all: bool = false  # If true, risks all current gold
@export var risk_amount: int = 10  # Amount to risk if not risking all
@export var success_chance: float = 0.7  # 70% by default
@export var multiplier: float = 2.0  # Multiplier on success (2.0 = double)
@export var failure_keeps_percentage: float = 0.0  # Percentage kept on failure (0 = lose all)

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add gold risk to results
	if not results.has("gold_risk"):
		results.gold_risk = []
	
	results.gold_risk.append({
		"risk_all": risk_all,
		"risk_amount": risk_amount,
		"success_chance": success_chance,
		"multiplier": multiplier,
		"failure_keeps_percentage": failure_keeps_percentage
	})
	
	var risk_desc = "all gold" if risk_all else "%d gold" % risk_amount
	print("Applied %s effect from %s (risk %s, %.0f%% chance for %.1fx)" % [
		get_effect_name(), 
		card_data.card_name, 
		risk_desc,
		success_chance * 100,
		multiplier
	])

func get_formatted_description() -> String:
	var percentage: int = int(success_chance * 100)
	var risk_desc = "all Gold" if risk_all else "%d Gold" % risk_amount
	
	if multiplier == 2.0:
		if failure_keeps_percentage <= 0.0:
			return "Risk %s. %d%% chance to double it, %d%% chance to lose it all" % [
				risk_desc, percentage, 100 - percentage
			]
		else:
			var keep_percent: int = int(failure_keeps_percentage * 100)
			return "Risk %s. %d%% chance to double it, %d%% chance to keep %d%%" % [
				risk_desc, percentage, 100 - percentage, keep_percent
			]
	else:
		if failure_keeps_percentage <= 0.0:
			return "Risk %s. %d%% chance to multiply by %.1fx, %d%% chance to lose it all" % [
				risk_desc, percentage, multiplier, 100 - percentage
			]
		else:
			var keep_percent: int = int(failure_keeps_percentage * 100)
			return "Risk %s. %d%% chance to multiply by %.1fx, %d%% chance to keep %d%%" % [
				risk_desc, percentage, multiplier, 100 - percentage, keep_percent
			]

func get_effect_name() -> String:
	return EFFECT_NAME