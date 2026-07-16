class_name RunCompleteIntent
extends SceneIntent

## Intent for showing the run completion screen.
## Contains summary data about the completed run.

## Was the run a victory?
var victory: bool = false

## Total time elapsed in seconds (optional)
var run_time: float = 0.0

## Total battles won (optional)
var battles_won: int = 0

## Curated-run summary fields (populated via from_summary())
var character_class: String = "Unknown"
var seed: int = 0
var final_health: int = 0
var final_sanity: int = 0
var cards_added: Array[String] = []

func _init(p_victory: bool = true, p_return_scene: String = "quick_duel_setup") -> void:
	super (p_return_scene)
	victory = p_victory

func get_intent_type() -> String:
	return "RunCompleteIntent"

## Factory for building a RunCompleteIntent from a RunSession.get_summary() Dictionary.
static func from_summary(summary: Dictionary) -> RunCompleteIntent:
	var intent := RunCompleteIntent.new(summary.get("victory", true), "main_menu")
	intent.character_class = summary.get("character_class", "Unknown")
	intent.seed = summary.get("seed", 0)
	intent.battles_won = summary.get("fights_won", 0)
	intent.final_health = summary.get("final_health", 0)
	intent.final_sanity = summary.get("final_sanity", 0)
	var cards: Array[String] = []
	cards.assign(summary.get("cards_added", []))
	intent.cards_added = cards
	return intent
