extends Resource
class_name LegacyCardEffectAdapter

# Converts legacy CardEffect instances into GameEffect instances

func to_game_effect(_legacy_effect: Resource) -> Resource:
	# TODO: map known legacy classes to new types
	# Example (pseudo): if legacy_effect is Heal: return HealthEffect.new() with mapped fields
	return null
