extends EncounterOutcome
class_name KarmaOutcome

const OUTCOME_NAME := "KarmaOutcome"

@export var karma_category: String = "wildlife"
@export var karma_amount: int = 1
@export var reason: String = ""
@export var narrative_description: String = ""

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var player_data = null
	
	# Get player data from game_state or via encounter_manager
	if game_state.has("player_data") and game_state.player_data != null:
		player_data = game_state.player_data
	elif encounter_manager and encounter_manager.game_manager:
		var gm = encounter_manager.game_manager
		if gm and gm.has_method("get_player_data"):
			player_data = gm.get_player_data()
	
	if not player_data or not player_data.has_method("add_karma"):
		GLog.error("PlayerData not available or doesn't support karma system")
		return
	
	player_data.add_karma(karma_category, karma_amount, reason)
	
	# Emit karma change notification via EventBus
	if encounter_manager and encounter_manager.event_bus:
		var cat_karma = player_data.get_karma(karma_category)
		var moral_karma = player_data.get_moral_karma()
		encounter_manager.event_bus.emit_signal("karma_changed", karma_category, cat_karma, moral_karma)
	
	GLog.debug("Applied %s: %s karma %+d (%s)" % [
		get_outcome_name(),
		karma_category,
		karma_amount,
		reason
	])

func get_formatted_description() -> String:
	if narrative_description != "":
		return narrative_description
	
	var karma_text = ""
	if karma_amount > 0:
		karma_text = "Your kindness is remembered"
	else:
		karma_text = "Your cruelty leaves a mark"
	
	match karma_category:
		"wildlife":
			if karma_amount > 0:
				return "The animals of the bush recognize your compassion"
			else:
				return "The creatures of the wild remember your cruelty"
		"strangers":
			if karma_amount > 0:
				return "Word spreads of your generosity to fellow travelers"
			else:
				return "Your selfishness toward strangers is whispered about"
		"community":
			if karma_amount > 0:
				return "The community sees you as a pillar of decency"
			else:
				return "Your actions damage your standing in the community"
		"business":
			if karma_amount > 0:
				return "Your fair dealing earns respect in trade"
			else:
				return "Your business practices leave a sour taste"
		"survival":
			if karma_amount > 0:
				return "Your mercy in desperate times shows true character"
			else:
				return "Your ruthlessness in survival haunts your conscience"
		_:
			return karma_text

func get_description_text() -> String:
	var sign_prefix = "+" if karma_amount > 0 else ""
	return "%s%d %s karma" % [sign_prefix, karma_amount, karma_category.capitalize()]

func get_outcome_name() -> String:
	return OUTCOME_NAME

func is_positive() -> bool:
	return karma_amount > 0

func is_negative() -> bool:
	return karma_amount < 0
