extends Area2D
class_name Card

@export var card_data: CardData
@export var card_instance: CardInstance

# Selection state
var is_selected: bool = false
var is_hovering: bool = false
var original_scale: Vector2
var original_z_index: int = 0  # Store original z-index for hand positioning
var is_quick_draw_highlighted: bool = false
var original_border_color: Color = Color.WHITE

# Signals
signal card_played(card)
## Removed unused signal to satisfy linter

func _ready():
	original_scale = scale
	
	# Enable input detection
	monitoring = true
	monitorable = true
	
	setup_card_visuals()
	setup_hover_effects()

# Accept either CardInstance or CardData and configure this node
func set_card(card) -> void:
	if card is CardInstance:
		card_instance = card
		card_data = card.card_data
	elif card is CardData:
		card_data = card
		card_instance = null
	setup_card_visuals()

func get_card_instance_or_null():
	return card_instance if card_instance else null

# Determine if this is a player card (for curio effect application)
func _is_player_card() -> bool:
	if card_instance:
		return card_instance.owner == CardInstance.Owner.PLAYER
	return true  # Default for preview/shop cards

func setup_card_visuals():
	if not card_data:
		return
		
	# Set card text
	if has_node("CardInfo/CardName"):
		$CardInfo/CardName.text = card_data.card_name
	if has_node("CardInfo/CardInfoContainer/EnergyCost"):
		# Check for curio cost modifications
		var base_cost = card_data.energy_cost
		var display_cost = base_cost
		var cost_modified = false

		if CurioManager:
			var mods = CurioManager.calculate_card_modifications(card_data, _is_player_card())
			var cost_reduction = mods.get("cost", 0)
			if cost_reduction != 0:
				display_cost = max(0, base_cost + cost_reduction)
				cost_modified = true

		# Display cost with green color if modified by curios
		$CardInfo/CardInfoContainer/EnergyCost.text = str(display_cost)
		if cost_modified:
			$CardInfo/CardInfoContainer/EnergyCost.add_theme_color_override("font_color", Color.LIME)
		else:
			# Reset to default blue color for energy cost
			$CardInfo/CardInfoContainer/EnergyCost.add_theme_color_override("font_color", Color(0, 0.5, 1, 1))
	if has_node("CardInfo/CardInfoContainer/Description"):
		var desc_node = $CardInfo/CardInfoContainer/Description
		var description_text = format_description()
		
		# Handle both Label and RichTextLabel
		if desc_node is RichTextLabel:
			desc_node.text = description_text
			desc_node.visible = true
			# Don't modulate - let BBCode colors show through
			desc_node.fit_content = true
		elif desc_node is Label:
			desc_node.text = description_text
			desc_node.visible = true
			desc_node.modulate = Color.BLACK
		else:
			print("Warning: Description node is type %s" % desc_node.get_class())
	
	# Set type symbol
	if has_node("TypeSymbol"):
		var type_symbol = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_symbol(card_data.card_type)
		$TypeSymbol.text = type_symbol
	
	# Set card colors
	var type_color = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_color(card_data.card_type)
	if has_node("CardBorder"):
		$CardBorder.color = type_color
		original_border_color = type_color
	if has_node("CardBackground"):
		$CardBackground.color = Color.WHITE
	
	# Set card handling info
	if has_node("CardInfo/CardInfoContainer/CardHandling"):
		var handling_text = format_card_handling()
		$CardInfo/CardInfoContainer/CardHandling.text = handling_text
		$CardInfo/CardInfoContainer/CardHandling.visible = handling_text.length() > 0
		
		# Style the CardHandling label
		if handling_text.length() > 0:
			$CardInfo/CardInfoContainer/CardHandling.add_theme_font_size_override("font_size", 10)
			$CardInfo/CardInfoContainer/CardHandling.add_theme_color_override("font_color", Color.ORANGE)
			$CardInfo/CardInfoContainer/CardHandling.add_theme_color_override("font_shadow_color", Color.BLACK)
			$CardInfo/CardInfoContainer/CardHandling.add_theme_constant_override("shadow_offset_x", 1)
			$CardInfo/CardInfoContainer/CardHandling.add_theme_constant_override("shadow_offset_y", 1)
	
	# Set sanity cost info
	if has_node("CardInfo/CardInfoContainer/SanityCost"):
		if card_data.sanity_cost > 0:
			$CardInfo/CardInfoContainer/SanityCost.text = "Sanity: %d" % card_data.sanity_cost
			$CardInfo/CardInfoContainer/SanityCost.visible = true
			$CardInfo/CardInfoContainer/SanityCost.add_theme_font_size_override("font_size", 10)
			$CardInfo/CardInfoContainer/SanityCost.add_theme_color_override("font_color", Color.PURPLE)
			$CardInfo/CardInfoContainer/SanityCost.add_theme_color_override("font_shadow_color", Color.BLACK)
		else:
			$CardInfo/CardInfoContainer/SanityCost.visible = false
	
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
	
	# Store original z-index and bring to front
	original_z_index = z_index
	z_index = 10  # Bring to front

func _on_mouse_exited():
	is_hovering = false
	
	# Return to original z-index (preserves hand positioning)
	z_index = original_z_index

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""Handle Area2D input events directly (fallback - usually button handles this)"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card_data:
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
	button.position = Vector2(-150, -210)
	button.size = Vector2(300, 420)
	
	add_child(button)
	button.pressed.connect(_on_button_clicked)

func _on_button_clicked():
	"""Handle button click"""
	if card_data:
		card_played.emit(self)
	else:
		print("ERROR: Card %s has no card_data!" % name)


func format_description() -> String:
	# Prefer CardInstance for context-aware descriptions (handles conditionals)
	# Fall back to CardData for basic effect descriptions
	if card_instance and card_instance.has_method("get_effect_descriptions"):
		return card_instance.get_effect_descriptions("\n")
	elif card_data:
		return card_data.get_effect_descriptions("\n")
	else:
		return ""

func format_card_handling() -> String:
	var handling_display = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_display_name(card_data.card_handling)
	return handling_display if handling_display != "Standard" else ""

func _input(event: InputEvent):
	"""Handle input events using collision detection (backup to button workaround)"""
	if event.is_action_pressed("left_mouse"):
		if is_hovering and card_data:
			card_played.emit(self)

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
	var base_color = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_color(card_data.card_type)
	if is_selected:
		# Highlight selected cards
		$CardBackground.color = base_color.lightened(0.3)
		position.y -= 10  # Lift selected cards slightly
	else:
		# Normal appearance
		$CardBackground.color = base_color
		position.y += 10 if position.y < 500 else 0  # Reset position if lifted

func set_quick_draw_highlight(enabled: bool) -> void:
	"""Highlight or unhighlight this card for quick draw/first turn bonus"""
	if not has_node("CardBorder"):
		return

	var border = $CardBorder

	if enabled:
		# Store original color if not already highlighted
		if not is_quick_draw_highlighted:
			original_border_color = border.color
		# Apply bright gold highlight
		border.color = Color(1.0, 0.85, 0.0)
		is_quick_draw_highlighted = true
	else:
		# Restore original type-based border color
		if card_data:
			var type_color = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_color(card_data.card_type)
			border.color = type_color
		is_quick_draw_highlighted = false

func show_as_card_back():
	"""Display this card as a card back (hide information)"""
	# Hide card info
	if has_node("CardInfo"):
		$CardInfo.visible = false
	
	# Show card back styling
	if has_node("CardBackground"):
		$CardBackground.color = Color(0.3, 0.2, 0.1, 1)  # Brown card back
	
	if has_node("CardInner"):
		$CardInner.color = Color(0.4, 0.3, 0.2, 1)  # Slightly lighter brown
	
	# Optional: Add card back pattern or text
	if has_node("TypeSymbol"):
		$TypeSymbol.text = "?"
		$TypeSymbol.visible = true

func update_energy_status(current_energy: int) -> void:
	if not has_node("CardInfo/CardInfoContainer/EnergyCost") or not card_data:
		return
		
	var base_cost = card_data.energy_cost
	var display_cost = base_cost
	var cost_modified = false

	if CurioManager:
		var mods = CurioManager.calculate_card_modifications(card_data, _is_player_card())
		var cost_reduction = mods.get("cost", 0)
		if cost_reduction != 0:
			display_cost = max(0, base_cost + cost_reduction)
			cost_modified = true
			
	# Update text just in case
	$CardInfo/CardInfoContainer/EnergyCost.text = str(display_cost)

	if current_energy < display_cost:
		$CardInfo/CardInfoContainer/EnergyCost.add_theme_color_override("font_color", Color.DARK_RED)
		modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		modulate = Color.WHITE
		if cost_modified:
			$CardInfo/CardInfoContainer/EnergyCost.add_theme_color_override("font_color", Color.LIME)
		else:
			$CardInfo/CardInfoContainer/EnergyCost.add_theme_color_override("font_color", Color(0, 0.5, 1, 1))

