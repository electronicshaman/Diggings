extends RefCounted
class_name EncounterOutcomeData

## Data class for collecting and storing encounter outcome information
## Used to pass outcome data from EncounterManager to the outcome display scene

# Narrative elements (collected from effects)
var narrative_texts: Array[String] = []
var karma_narratives: Array[String] = []

# Mechanical rewards/consequences
var gold_change: int = 0
var health_change: int = 0
var karma_changes: Dictionary = {}  # category -> amount
var corruption_change: int = 0
var sanity_change: int = 0
var curios_gained: Array = []
var cards_gained: Array = []

# Special outcomes
var combat_triggered: bool = false
var enemy_name: String = ""

# Choice context
var choice_text: String = ""


func has_any_content() -> bool:
	"""Check if there is any content to display"""
	return not narrative_texts.is_empty() or \
		   not karma_narratives.is_empty() or \
		   gold_change != 0 or \
		   health_change != 0 or \
		   not karma_changes.is_empty() or \
		   corruption_change != 0 or \
		   sanity_change != 0 or \
		   not curios_gained.is_empty() or \
		   not cards_gained.is_empty() or \
		   combat_triggered


func get_combined_narrative() -> String:
	"""Get all narrative texts combined into a single string"""
	var combined = ""
	for text in narrative_texts:
		if text != "":
			combined += text + "\n\n"
	return combined.strip_edges()


func get_primary_karma_narrative() -> String:
	"""Get the first karma narrative (for flavor display)"""
	if not karma_narratives.is_empty():
		return karma_narratives[0]
	return ""
