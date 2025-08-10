extends Control
class_name MapNodeScene

const DEBUG_ENABLED: bool = true

# Node references
@onready var node_button: Button = $NodeButton
@onready var background_icon: TextureRect = $BackgroundIcon
@onready var node_icon: TextureRect = $NodeIcon
@onready var node_label: Label = $NodeLabel
@onready var state_indicator: Control = $StateIndicator
@onready var outline: ColorRect = $StateIndicator/Outline
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Node data and state
var node_data: MapNode
var node_id: String = ""
var is_interactive: bool = false
var is_highlighted: bool = false

# Visual settings
@export var node_size: Vector2 = Vector2(64, 64)
@export var label_offset: Vector2 = Vector2(0, 70)

# Data-driven visual system - all colors come from NodeConfig resources

# Signals
signal node_clicked(node_id: String, event: InputEvent)
signal node_hovered(node_id: String)
signal node_unhovered()
signal action_requested(node_id: String, action_name: String)

func _ready():
	# Set up the base scene structure
	setup_visual_hierarchy()
	connect_signals()

func setup_visual_hierarchy():
	"""Set up the visual layout and styling"""
	# Configure main control
	custom_minimum_size = node_size
	size = node_size
	
	# Only configure nodes if they exist
	if node_button:
		node_button.flat = true
		node_button.custom_minimum_size = node_size
		node_button.size = node_size
		node_button.position = Vector2.ZERO
	
	if background_icon:
		background_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		background_icon.size = node_size
		background_icon.position = Vector2.ZERO
	
	if node_icon:
		node_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node_icon.size = node_size * 0.7  # Slightly smaller than background
		node_icon.position = node_size * 0.15  # Center it
	
	if node_label:
		node_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		node_label.position = label_offset
		node_label.size = Vector2(node_size.x + 40, 20)  # Wider for text
	
	if state_indicator:
		state_indicator.size = node_size + Vector2(8, 8)  # Slightly larger
		state_indicator.position = Vector2(-4, -4)  # Centered offset
	
	if outline:
		outline.size = state_indicator.size if state_indicator else node_size + Vector2(8, 8)
		outline.position = Vector2.ZERO
		outline.color = Color.TRANSPARENT

func connect_signals():
	"""Connect internal signals"""
	if node_button:
		node_button.pressed.connect(_on_button_pressed)
		node_button.mouse_entered.connect(_on_mouse_entered)
		node_button.mouse_exited.connect(_on_mouse_exited)

func setup_node(id: String, data: MapNode):
	"""Initialize this scene with node data"""
	node_id = id
	node_data = data
	
	if not node_data:
		GLog.error("MapNodeScene setup failed: no node data provided")
		return
	
	# Apply type-specific customizations
	apply_type_customizations()
	
	# Set visual elements based on node data
	update_visuals()
	update_interactivity()
	
	GLog.debug("MapNodeScene setup complete for: " + node_data.get_type_name() + " (" + id + ")")

func apply_type_customizations():
	"""Apply visual customizations from node's resource configuration"""
	if not node_data or not node_data.config:
		GLog.error("MapNodeScene cannot apply customizations without NodeConfig")
		return
	
	# All visual properties come from the NodeConfig resource
	node_size = node_data.get_visual_size()
	
	# Apply the size to the control
	custom_minimum_size = node_size
	size = node_size
	
	# Update child node sizes to match
	setup_visual_hierarchy()

func update_visuals():
	"""Update all visual elements based on current node data and state"""
	if not node_data:
		return
	
	# Update label
	if node_label:
		node_label.text = node_data.get_type_name()
		node_label.modulate = get_label_color()
	
	# Update background based on type
	if background_icon:
		background_icon.modulate = get_background_color()
		# Set background texture if available
		if node_data.config and node_data.config.background_texture:
			background_icon.texture = node_data.config.background_texture
	
	# Update main icon
	if node_icon:
		node_icon.modulate = get_icon_color()
		# Set icon texture if available
		if node_data.config and node_data.config.icon_texture:
			node_icon.texture = node_data.config.icon_texture
	
	# Update state indicator
	update_state_indicator()
	
	# Update tooltip
	update_tooltip()

func update_state_indicator():
	"""Update the visual state indicator (outline, glow, etc.)"""
	if not outline or not node_data or not node_data.config:
		return
	
	var state = node_data.get_state()
	var glow_color = node_data.get_glow_color()
	
	# Handle special states
	if is_highlighted:
		outline.color = Color(Color.CYAN.r, Color.CYAN.g, Color.CYAN.b, 0.8)
	elif state == MapNode.NodeState.CURRENT:
		outline.color = glow_color
	elif state == MapNode.NodeState.AVAILABLE and is_interactive:
		# Use resource glow color but make it more subtle for available state
		outline.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.6)
	elif state == MapNode.NodeState.LOCKED:
		outline.color = Color.TRANSPARENT
	else:
		outline.color = Color.TRANSPARENT

func get_background_color() -> Color:
	"""Get the background color using resource-defined state colors exactly"""
	if not node_data or not node_data.config:
		return Color.WHITE
	
	# Use the state color exactly as defined in the MapNodeConfig resource
	return node_data.get_state_color()

func get_icon_color() -> Color:
	"""Get the icon color based on node state"""
	var alpha = node_data.get_state_alpha()
	return Color(1.0, 1.0, 1.0, alpha)

func get_label_color() -> Color:
	"""Get the label color from the node's resource configuration"""
	if not node_data or not node_data.config:
		return Color.WHITE
		
	return node_data.config.get_state_color(node_data.get_state())

func get_current_resource_modulate() -> Color:
	"""Get the current modulate color using resource-defined state colors exactly"""
	if not node_data or not node_data.config:
		return Color.WHITE
	
	# Use the state color exactly as defined in the MapNodeConfig resource
	return node_data.get_state_color()

func update_interactivity():
	"""Update whether this node can be interacted with"""
	if not node_button or not node_data:
		return
	
	var new_interactive = node_data.is_interactive()
	
	if new_interactive != is_interactive:
		is_interactive = new_interactive
		
		# Update button state
		node_button.disabled = not is_interactive
		
		# Visual feedback for interactivity
		if is_interactive:
			node_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			node_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		
		# Update visual appearance
		update_state_indicator()

func update_tooltip():
	"""Update the tooltip based on current node state and available actions"""
	if not node_button or not node_data:
		return
	
	var tooltip_content = node_data.get_description()
	
	# Add custom properties from the config if they exist
	if node_data.config:
		var custom_props = node_data.config.custom_properties
		
		# Build tooltip from custom properties dynamically
		if custom_props.has("tooltip_extras"):
			var extras = custom_props["tooltip_extras"]
			if extras is Array:
				for extra in extras:
					tooltip_content += "\n- " + str(extra)
	
	# Add state information
	match node_data.get_state():
		MapNode.NodeState.LOCKED:
			tooltip_content += "\n[Locked - Cannot access]"
		MapNode.NodeState.CURRENT:
			tooltip_content += "\n[Current Location]"
		MapNode.NodeState.COMPLETED:
			if node_data.can_revisit():
				tooltip_content += "\n[Can revisit]"
			else:
				tooltip_content += "\n[Already completed]"
	
	# Add available actions (simplified)
	if is_interactive and node_data.actions.size() > 0:
		tooltip_content += "\n\nAvailable actions: " + str(node_data.actions.size())
	
	node_button.tooltip_text = tooltip_content

func set_highlight(highlighted: bool):
	"""Set whether this node should be highlighted"""
	if highlighted != is_highlighted:
		is_highlighted = highlighted
		update_state_indicator()
		
		# Play highlight animation if available
		if animation_player and animation_player.has_animation("highlight"):
			if highlighted:
				animation_player.play("highlight")
			else:
				animation_player.play("unhighlight")

func play_select_animation():
	"""Play selection animation"""
	if animation_player and animation_player.has_animation("select"):
		animation_player.play("select")
	else:
		# Get the proper resource-based color to restore to
		var base_color = get_current_resource_modulate()
		
		# Fallback animation using tween
		var tween = create_tween()
		tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		tween.parallel().tween_property(self, "modulate", base_color, 0.1)
		
		# Check for pulse effect from config
		if node_data and node_data.config and node_data.config.pulse_effect:
			# Dramatic flash effect for nodes with pulse enabled - blend with resource color
			var pulse_color = node_data.config.visual_color
			var blended_pulse = Color(pulse_color.r, pulse_color.g, pulse_color.b, base_color.a)
			tween.parallel().tween_property(self, "modulate", blended_pulse, 0.2)
			tween.parallel().tween_property(self, "modulate", base_color, 0.1)

func play_discover_animation():
	"""Play discovery animation when node becomes visible"""
	if animation_player and animation_player.has_animation("discover"):
		animation_player.play("discover")

# Event handlers
func _on_button_pressed():
	"""Handle button press - emit click signal"""
	GLog.debug("MapNodeScene button pressed: " + node_id)
	
	# Play selection animation
	play_select_animation()
	
	# Emit the click signal
	var dummy_event = InputEventMouseButton.new()
	dummy_event.button_index = MOUSE_BUTTON_LEFT
	dummy_event.pressed = true
	node_clicked.emit(node_id, dummy_event)

func _on_mouse_entered():
	"""Handle mouse hover enter"""
	node_hovered.emit(node_id)
	
	# Visual feedback
	if is_interactive:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited():
	"""Handle mouse hover exit"""
	node_unhovered.emit()
	
	# Reset visual feedback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# Public interface for external control
func refresh():
	"""Refresh all visuals and state"""
	update_visuals()
	update_interactivity()

func set_node_data(data: MapNode):
	"""Update the node data and refresh"""
	node_data = data
	refresh()

func get_node_data() -> MapNode:
	"""Get the current node data"""
	return node_data

func set_position_centered(pos: Vector2):
	"""Set position with the node centered on the given point"""
	position = pos - (node_size * 0.5)

# Animation support methods
func fade_in(duration: float = 0.3):
	"""Fade the node in"""
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration)

func fade_out(duration: float = 0.3):
	"""Fade the node out"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): visible = false)
