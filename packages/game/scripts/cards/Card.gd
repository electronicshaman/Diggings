extends Area2D
class_name Card

@export var card_data: CardData

# Selection state
var is_selected: bool = false
var is_hovering: bool = false
var original_scale: Vector2
var original_z_index: int = 0  # Store original z-index for hand positioning

# Signals
signal card_played(card)
signal card_effects_applied(card, effects)

func _ready():
	original_scale = scale
	
	# Enable input detection
	monitoring = true
	monitorable = true
	
	setup_card_visuals()
	setup_hover_effects()
	
	print("DEBUG: Card %s ready using GUI input workaround" % name)
	print("DEBUG: Card position: %s, scale: %s" % [position, scale])

func setup_card_visuals():
	if not card_data:
		return
		
	# Set card text
	if has_node("CardInfo/CardName"):
		$CardInfo/CardName.text = card_data.card_name
	if has_node("CardInfo/EnergyCost"):
		$CardInfo/EnergyCost.text = str(card_data.energy_cost)
	if has_node("CardInfo/Description"):
		var desc_node = $CardInfo/Description
		var description_text = format_description()
		
		# Handle both Label and RichTextLabel
		if desc_node is RichTextLabel:
			desc_node.text = description_text
			desc_node.visible = true
			desc_node.modulate = Color.BLACK
			desc_node.fit_content = true
		elif desc_node is Label:
			desc_node.text = description_text
			desc_node.visible = true
			desc_node.modulate = Color.BLACK
		else:
			print("Warning: Description node is type %s" % desc_node.get_class())
	
	# Set type symbol
	if has_node("TypeSymbol"):
		var type_symbol = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_symbol(card_data.card_type) if ThemeManager else "?"
		$TypeSymbol.text = type_symbol
	
	# Set card colors
	var type_color = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_color(card_data.card_type) if ThemeManager else Color.WHITE
	if has_node("CardBorder"):
		$CardBorder.color = type_color
	if has_node("CardBackground"):
		$CardBackground.color = Color.WHITE
	
	# Set card handling info
	if has_node("CardInfo/CardHandling"):
		var handling_text = format_card_handling()
		$CardInfo/CardHandling.text = handling_text
		$CardInfo/CardHandling.visible = handling_text.length() > 0
		
		# Style the CardHandling label
		if handling_text.length() > 0:
			$CardInfo/CardHandling.add_theme_font_size_override("font_size", 10)
			$CardInfo/CardHandling.add_theme_color_override("font_color", Color.ORANGE)
			$CardInfo/CardHandling.add_theme_color_override("font_shadow_color", Color.BLACK)
			$CardInfo/CardHandling.add_theme_constant_override("shadow_offset_x", 1)
			$CardInfo/CardHandling.add_theme_constant_override("shadow_offset_y", 1)
	
	# Set sanity cost info
	if has_node("CardInfo/SanityCost"):
		if card_data.sanity_cost > 0:
			$CardInfo/SanityCost.text = "Sanity: %d" % card_data.sanity_cost
			$CardInfo/SanityCost.visible = true
			$CardInfo/SanityCost.add_theme_font_size_override("font_size", 10)
			$CardInfo/SanityCost.add_theme_color_override("font_color", Color.PURPLE)
			$CardInfo/SanityCost.add_theme_color_override("font_shadow_color", Color.BLACK)
		else:
			$CardInfo/SanityCost.visible = false
	
	# Hide card image placeholder for now - it's covering the text
	if has_node("CardImage"):
		$CardImage.visible = false

func setup_hover_effects():
	# Connect mouse enter/exit signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Connect Area2D input_event signal as fallback
	input_event.connect(_on_area_input_event)
	
	# Add invisible button for reliable clicking
	add_click_button()

func _on_mouse_entered():
	is_hovering = true
	print("DEBUG: Mouse entered card %s at position %s" % [name, position])
	
	# Store original z-index and bring to front
	original_z_index = z_index
	z_index = 10  # Bring to front

func _on_mouse_exited():
	is_hovering = false
	print("DEBUG: Mouse exited card %s" % name)
	
	# Return to original z-index (preserves hand positioning)
	z_index = original_z_index

func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Handle Area2D input events directly"""
	print("DEBUG: Area2D input event on card %s: %s" % [name, event])
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("DEBUG: Area2D detected left click on card %s!" % name)
		if card_data:
			print("DEBUG: Card has data, emitting card_played signal for: %s" % card_data.card_name)
			card_played.emit(self)
		else:
			print("ERROR: Card %s has no card_data!" % name)

func add_click_button():
	"""Add an invisible button for reliable click detection"""
	var button = Button.new()
	button.name = "ClickButton"
	button.flat = true
	button.modulate = Color.TRANSPARENT
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Position button to cover the card area
	button.position = Vector2(-75, -100)
	button.size = Vector2(150, 200)
	
	add_child(button)
	button.pressed.connect(_on_button_clicked)
	
	print("DEBUG: Added click button to card %s" % name)

func _on_button_clicked():
	"""Handle button click"""
	print("DEBUG: Button clicked on card %s!" % name)
	if card_data:
		print("DEBUG: Card has data, emitting card_played signal for: %s" % card_data.card_name)
		card_played.emit(self)
	else:
		print("ERROR: Card %s has no card_data!" % name)


func format_description() -> String:
	var desc_parts = []
	
	# Add modular effect descriptions
	for effect in card_data.effects:
		if effect:
			desc_parts.append(effect.get_formatted_description())
	
	# Join with periods
	var base_desc = ". ".join(desc_parts)
	if base_desc.length() > 0:
		base_desc += "."
	
	# Add custom description if provided
	if card_data.description.length() > 0:
		if base_desc.length() > 0:
			return base_desc + " " + card_data.description
		else:
			return card_data.description
	
	return base_desc

func format_card_handling() -> String:
	if not ThemeManager:
		return ""
	var handling_display = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_display_name(card_data.card_handling)
	return handling_display if handling_display != "Standard" else ""

func _input(event: InputEvent):
	"""Handle input events using collision detection (workaround for broken Area2D input_event)"""
	if event.is_action_pressed("left_mouse"):
		print("DEBUG: Left mouse pressed detected by card %s (hover: %s)" % [name, is_hovering])
		# Check if mouse is hovering over this card (using the working mouse_entered/exited detection)
		if is_hovering:
			print("DEBUG: Card %s clicked using collision detection workaround!" % name)
			
			if card_data:
				print("DEBUG: Card has data, emitting card_played signal for: %s" % card_data.card_name)
				card_played.emit(self)
			else:
				print("ERROR: Card %s has no card_data!" % name)

# NOTE: Card effects are now handled by CardEffects.gd - this function is deprecated
# and kept only for reference. The actual effects are calculated in CardEffects.apply_card_effects()
func get_card_effects() -> Dictionary:
	# This function is no longer used - effects are handled by CardEffects system
	print("WARNING: get_card_effects() is deprecated - use CardEffects.apply_card_effects() instead")
	return {}	

func set_selected(selected: bool):
	is_selected = selected
	update_visual_state()

func update_visual_state():
	var base_color = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_color(card_data.card_type) if ThemeManager else Color.WHITE
	if is_selected:
		# Highlight selected cards
		$CardBackground.color = base_color.lightened(0.3)
		position.y -= 10  # Lift selected cards slightly
	else:
		# Normal appearance
		$CardBackground.color = base_color
		position.y += 10 if position.y < 500 else 0  # Reset position if lifted
