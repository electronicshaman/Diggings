@tool
extends EditorScript

const DEBUG_ENABLED: bool = true

func _run():
	GLog.info("Creating example curios...")
	
	# Create Lucky Nugget
	create_lucky_nugget()
	
	# Create Thick Leather
	create_thick_leather()
	
	# Create Old Compass
	create_old_compass()
	
	# Create Sharpened Blade
	create_sharpened_blade()
	
	GLog.info("Example curios created!")

func create_lucky_nugget():
	var curio = CurioData.new()
	curio.curio_name = "Lucky Nugget"
	curio.description = "+3 gold at the start of each combat"
	curio.flavor_text = "A small nugget that seems to attract wealth"
	curio.mechanical_category = "Resource"
	curio.rarity = "Common"
	curio.gold_cost = 100
	
	# Create the effect
	var effect = preload("res://scripts/curios/effects/resource_gain.gd").new()
	effect.trigger_event = "combat_start"
	effect.resource_type = "gold"
	effect.amount = 3
	
	curio.effects = [effect]
	
	# Set class synergies
	curio.bushranger_synergy = 1.0
	curio.prospector_synergy = 1.3  # Good for Prospector
	curio.tracker_synergy = 1.0
	curio.publican_synergy = 1.0
	
	# Save the resource
	ResourceSaver.save(curio, "res://data/curios/common/lucky_nugget.tres")
	GLog.debug("Created Lucky Nugget")

func create_thick_leather():
	var curio = CurioData.new()
	curio.curio_name = "Thick Leather"
	curio.description = "+1 block at the start of each turn"
	curio.flavor_text = "Tough outback leather that never seems to wear"
	curio.mechanical_category = "Passive"
	curio.rarity = "Common"
	curio.gold_cost = 120
	
	# Create the effect
	var effect = preload("res://scripts/curios/effects/resource_gain.gd").new()
	effect.trigger_event = "turn_start"
	effect.resource_type = "defense"
	effect.amount = 1
	
	curio.effects = [effect]
	
	# Set class synergies
	curio.bushranger_synergy = 0.9
	curio.prospector_synergy = 1.0
	curio.tracker_synergy = 1.2  # Good for defensive Tracker
	curio.publican_synergy = 1.1
	
	# Save the resource
	ResourceSaver.save(curio, "res://data/curios/common/thick_leather.tres")
	GLog.debug("Created Thick Leather")

func create_old_compass():
	var curio = CurioData.new()
	curio.curio_name = "Old Compass"
	curio.description = "Draw 1 additional card at the start of combat"
	curio.flavor_text = "It doesn't point north, but it points somewhere useful"
	curio.mechanical_category = "Resource"
	curio.rarity = "Common"
	curio.gold_cost = 150
	
	# Create the effect
	var effect = preload("res://scripts/curios/effects/resource_gain.gd").new()
	effect.trigger_event = "combat_start"
	effect.resource_type = "cards"
	effect.amount = 1
	
	curio.effects = [effect]
	
	# Set class synergies - good for everyone
	curio.bushranger_synergy = 1.1
	curio.prospector_synergy = 1.1
	curio.tracker_synergy = 1.2  # Great for setup
	curio.publican_synergy = 1.1
	
	# Save the resource
	ResourceSaver.save(curio, "res://data/curios/common/old_compass.tres")
	GLog.debug("Created Old Compass")

func create_sharpened_blade():
	var curio = CurioData.new()
	curio.curio_name = "Sharpened Blade"
	curio.description = "Attack cards deal +1 damage"
	curio.flavor_text = "Honed to a razor's edge in the harsh outback"
	curio.mechanical_category = "Modifier"
	curio.rarity = "Common"
	curio.gold_cost = 140
	
	# Create the effect
	var effect = preload("res://scripts/curios/effects/card_modifier.gd").new()
	effect.trigger_event = "card_played"
	effect.target_card_type = "attack"
	effect.modification_type = "damage"
	effect.modification_value = 1
	
	curio.effects = [effect]
	
	# Set class synergies
	curio.bushranger_synergy = 1.3  # Great for attack-focused Bushranger
	curio.prospector_synergy = 1.0
	curio.tracker_synergy = 1.0
	curio.publican_synergy = 0.9
	
	# Save the resource
	ResourceSaver.save(curio, "res://data/curios/common/sharpened_blade.tres")
	GLog.debug("Created Sharpened Blade")