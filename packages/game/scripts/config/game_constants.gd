class_name GameConstants
extends RefCounted

const DEBUG_ENABLED: bool = true

enum CardType {
	ATTACK,
	SKILL, 
	POWER,
	FORTUNE
}

enum DuelPhase {
	PLAYER_TURN,
	ENEMY_TURN,
	RESOLVING_EFFECTS,
	DUEL_END
}

enum ResourceType {
	HEALTH,
	SANITY,
	ENERGY,
	GOLD,
	CORRUPTION
}

const DEFAULT_PLAYER_VALUES: Dictionary = {
	"max_health": 100,
	"max_sanity": 100,
	"max_energy": 3,
	"starting_gold": 100,
	"starting_hand_size": 5,
	"max_hand_size": 10,
	"cards_per_turn": 1
}

const UI_VALUES: Dictionary = {
	"card_spacing": 160,
	"card_width": 150,
	"card_height": 200,
	"hand_y_offset": 0,
	"tooltip_delay": 0.5,
	"animation_duration": 0.3
}

const DUEL_VALUES: Dictionary = {
	"max_turns": 50,
	"deck_shuffle_threshold": 5,
	"energy_refresh_per_turn": 3,
	"block_decay_per_turn": 0,
	"starting_deck_size": 15,
	"max_deck_size": 50
}

const CARD_VALUES: Dictionary = {
	"max_cost": 10,
	"min_cost": 0,
	"max_damage": 50,
	"max_block": 50,
	"max_healing": 30,
	"status_max_stacks": 99
}

const BALANCE_VALUES: Dictionary = {
	"damage_variance": 0.0,
	"critical_chance_base": 0.05,
	"critical_multiplier": 1.5,
	"block_efficiency": 1.0,
	"healing_efficiency": 1.0,
	"energy_cost_modifier": 1.0
}

const PROGRESSION_VALUES: Dictionary = {
	"floors_per_act": 15,
	"max_acts": 4,
	"elite_floor_frequency": 8,
	"shop_floor_frequency": 7,
	"rest_site_frequency": 6,
	"boss_floors": [15, 30, 45, 60]
}

const VISUAL_EFFECTS: Dictionary = {
	"damage_number_duration": 2.0,
	"card_play_animation": 0.5,
	"screen_shake_intensity": 10.0,
	"particle_lifetime": 3.0,
	"flash_duration": 0.2
}

const AUDIO_VALUES: Dictionary = {
	"master_volume_db_range": [-40.0, 0.0],
	"sfx_volume_db_range": [-30.0, 0.0],
	"music_volume_db_range": [-30.0, 0.0],
	"fade_in_duration": 1.0,
	"fade_out_duration": 0.5
}

const DEBUG_VALUES: Dictionary = {
	"god_mode": false,
	"unlimited_energy": false,
	"skip_animations": false,
	"show_enemy_intents": true,
	"log_all_events": false
}

const FILE_PATHS: Dictionary = {
	"save_directory": "user://saves/",
	"settings_file": "user://settings.cfg", 
	"statistics_file": "user://statistics.dat",
	"unlocks_file": "user://unlocks.dat"
}



const STATUS_EFFECTS: Array[String] = [
	"poison",
	"burn",
	"curse",
	"vulnerable",
	"weak",
	"frail",
	"strength",
	"dexterity",
	"vigor",
	"focus"
]

const RARITY_COLORS: Dictionary = {
	"common": Color.WHITE,
	"uncommon": Color.GREEN,
	"rare": Color.BLUE,
	"epic": Color.PURPLE,
	"legendary": Color.GOLD
}

const CARD_TYPE_COLORS: Dictionary = {
	CardType.ATTACK: Color.RED,
	CardType.SKILL: Color.GREEN,
	CardType.POWER: Color.BLUE,
	CardType.FORTUNE: Color.PURPLE
}

static func get_card_type_name(card_type: CardType) -> String:
	match card_type:
		CardType.ATTACK: return "Attack"
		CardType.SKILL: return "Skill"
		CardType.POWER: return "Power"
		CardType.FORTUNE: return "Fortune"
		_: return "Unknown"

# Convert enum to string (alias for consistency)
static func card_type_to_string(card_type: CardType) -> String:
	return get_card_type_name(card_type)

# Convert string to enum
static func string_to_card_type(card_type_string: String) -> CardType:
	match card_type_string:
		"Attack": return CardType.ATTACK
		"Skill": return CardType.SKILL
		"Power": return CardType.POWER
		"Fortune": return CardType.FORTUNE
		_: return CardType.ATTACK

static func get_themed_card_type_name(card_type: CardType, theme: String = "the_rush") -> String:
	var card_type_string = get_card_type_name(card_type)
	return ThemeManager.get_card_display_name(card_type_string, theme)

static func get_resource_color(resource_type: ResourceType) -> Color:
	match resource_type:
		ResourceType.HEALTH: return Color.RED
		ResourceType.SANITY: return Color.CYAN
		ResourceType.ENERGY: return Color.YELLOW
		ResourceType.GOLD: return Color.GOLD
		ResourceType.CORRUPTION: return Color.PURPLE
		_: return Color.WHITE

static func clamp_resource_value(value: int, resource_type: ResourceType, max_value: int) -> int:
	match resource_type:
		ResourceType.HEALTH, ResourceType.SANITY:
			return clampi(value, 0, max_value)
		ResourceType.ENERGY:
			return clampi(value, 0, max_value)
		ResourceType.GOLD:
			return maxi(value, 0)
		ResourceType.CORRUPTION:
			return maxi(value, 0)
		_:
			return value

static func is_debug_build() -> bool:
	return OS.is_debug_build()

static func get_difficulty_modifier(difficulty: int) -> Dictionary:
	var base_modifiers := {
		"enemy_health": 1.0,
		"enemy_damage": 1.0,
		"player_health": 1.0,
		"gold_gain": 1.0,
		"card_reward_count": 3
	}
	
	match difficulty:
		1: return base_modifiers
		2: 
			base_modifiers["enemy_health"] = 1.2
			base_modifiers["enemy_damage"] = 1.1
		3:
			base_modifiers["enemy_health"] = 1.5
			base_modifiers["enemy_damage"] = 1.3
			base_modifiers["player_health"] = 0.8
		4:
			base_modifiers["enemy_health"] = 2.0
			base_modifiers["enemy_damage"] = 1.5
			base_modifiers["player_health"] = 0.6
			base_modifiers["gold_gain"] = 0.8
		5:
			base_modifiers["enemy_health"] = 3.0
			base_modifiers["enemy_damage"] = 2.0
			base_modifiers["player_health"] = 0.5
			base_modifiers["gold_gain"] = 0.5
			base_modifiers["card_reward_count"] = 2
	
	return base_modifiers