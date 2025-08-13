extends Node2D
class_name MapNodeScene

const DEBUG_ENABLED: bool = true

# Node references
@onready var click_area: Area2D = $ClickArea
@onready var background_icon: MeshInstance2D = $BackgroundIcon
@onready var node_icon: MeshInstance2D = $NodeIcon
# @onready var node_label: Label = $NodeLabel  # Removed - using tooltips instead
@onready var state_indicator: Node2D = $StateIndicator
@onready var outline: MeshInstance2D = $StateIndicator/Outline
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Node data and state
var node_data: MapNode
var node_id: String = ""
var is_interactive: bool = false
var is_highlighted: bool = false

# Visual settings
@export var node_size: Vector2 = Vector2(32, 32)
# @export var label_offset: Vector2 = Vector2(0, 70)  # Removed - no longer needed

# Data-driven visual system - all colors come from NodeConfig resources

# Debug overlay label (created on demand)
var debug_label: Label = null

# Signals
signal node_clicked(node_id: String, event: InputEvent)
signal node_hovered(node_id: String)
signal node_unhovered()
## Removed unused signal to avoid lint warnings

func _ready():
	# Set up the base scene structure
	setup_visual_hierarchy()
	connect_signals()

# Global mouse detection to see if ANY events reach this node
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var global_pos = event.global_position
		var local_pos = to_local(global_pos)
		var rect = Rect2(Vector2.ZERO, node_size)
		if rect.has_point(local_pos):
			GLog.info("🎯 GLOBAL MOUSE over " + node_id + " at " + str(local_pos))

func setup_visual_hierarchy():
	"""Set up the visual layout and styling"""
	# Node2D doesn't have size properties like Control nodes
	# All sizing is handled by child nodes
	
	# Configure click area if it exists
	if click_area:
		# Area2D doesn't need size configuration, handled by CollisionShape2D
		pass
	
	if background_icon:
		# MeshInstance2D positioning - centered on the node
		background_icon.position = node_size * 0.5
		if background_icon.mesh is QuadMesh:
			(background_icon.mesh as QuadMesh).size = node_size
	
	if node_icon:
		# Slightly smaller than background, centered
		node_icon.position = node_size * 0.5
		if node_icon.mesh is QuadMesh:
			(node_icon.mesh as QuadMesh).size = node_size * 0.7
	
	# Label configuration removed - using tooltips instead
	
	if state_indicator:
		# Offset for outline effect
		state_indicator.position = Vector2(-4, -4)
	
	if outline:
		# Centered on the state indicator with larger size for outline
		outline.position = node_size * 0.5 + Vector2(4, 4)  # Offset to center
		outline.modulate = Color.TRANSPARENT
		if outline.mesh is QuadMesh:
			(outline.mesh as QuadMesh).size = node_size + Vector2(8, 8)

func connect_signals():
	"""Connect internal signals"""
	if click_area:
		click_area.input_event.connect(_on_area_input_event)
		click_area.mouse_entered.connect(_on_mouse_entered)
		click_area.mouse_exited.connect(_on_mouse_exited)
		pass  # Signals connected
	else:
		GLog.error("CRITICAL: click_area is NULL - signals not connected!")

func setup_node(id: String, data: MapNode):
	"""Initialize this scene with node data"""
	node_id = id
	node_data = data
	
	# Setup node data
	
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
	
	# Node2D doesn't have size properties like Control nodes
	# Size is managed by child nodes
	
	# Update child node sizes to match
	setup_visual_hierarchy()

func update_visuals():
	"""Update all visual elements based on current node data and state"""
	if not node_data or not node_data.config:
		GLog.error("MapNodeScene.update_visuals() called without node data or config")
		return
	
	# Get the explicit color from resource based on current state
	var state_color = node_data.config.get_state_color(node_data.get_state())
	var base_visual_color = node_data.config.visual_color
	
	if DEBUG_ENABLED:
		GLog.debug("Updating visuals for " + node_id + " - State: " + str(node_data.get_state()) + ", State Color: " + str(state_color) + ", Visual Color: " + str(base_visual_color))
	
	# Update background using explicit resource color
	if background_icon:
		# Use state-specific color for background
		background_icon.modulate = state_color
	
	# Update main icon using explicit resource color
	if node_icon:
		# Use base visual color for the main icon
		node_icon.modulate = base_visual_color
	
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
		# Use resource-defined glow color instead of hardcoded cyan
		outline.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.8)
	elif state == MapNode.NodeState.CURRENT:
		outline.modulate = glow_color
	elif state == MapNode.NodeState.AVAILABLE and is_interactive:
		# Use resource glow color but make it more subtle for available state
		outline.modulate = Color(glow_color.r, glow_color.g, glow_color.b, 0.6)
	elif state == MapNode.NodeState.LOCKED:
		outline.modulate = Color.TRANSPARENT
	else:
		outline.modulate = Color.TRANSPARENT


func update_interactivity():
	"""Update whether this node can be interacted with"""
	if not click_area or not node_data:
		return
	
	var new_interactive = node_data.is_interactive()
	
	if new_interactive != is_interactive:
		is_interactive = new_interactive
		
		# Update Area2D pickable state
		click_area.input_pickable = is_interactive
		
		# Interactivity updated
		
		# Note: Node2D doesn't have mouse_default_cursor_shape
		# Cursor changes would need to be handled differently if needed
		
		# Update visual appearance
		update_state_indicator()

func update_tooltip():
	"""Update the tooltip based on current node state and available actions"""
	if not node_data:
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
	
	# Note: Node2D doesn't have tooltip_text property.
	# In DEBUG, we can log the computed tooltip for verification.
	if DEBUG_ENABLED:
		GLog.debug("Tooltip for " + node_id + ":\n" + tooltip_content)

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
		# Get the current resource-based color for animation
		var base_color = node_data.config.get_state_color(node_data.get_state()) if node_data and node_data.config else Color.WHITE
		
		# Fallback animation using tween with modulate effects
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

# Debug helpers
func update_debug_badge(text: String, color: Color = Color.WHITE):
	"""Show or update a tiny debug label above the node without intercepting input"""
	if not debug_label:
		debug_label = Label.new()
		debug_label.name = "DebugLabel"
		# Ensure this Control doesn't steal mouse input from Area2D
		debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Smaller text and positioned slightly above the node center
		debug_label.scale = Vector2(0.75, 0.75)
		add_child(debug_label)
	# Position relative to current node size (above the top a bit)
	debug_label.position = Vector2(node_size.x * 0.5 - 6.0, -12.0)
	debug_label.text = text
	debug_label.modulate = color
	debug_label.visible = true

func clear_debug_badge():
	"""Hide the debug label if present"""
	if debug_label:
		debug_label.visible = false

# Event handlers
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""Handle Area2D input events"""
	GLog.info("🎯 AREA2D EVENT on " + node_id + ": " + str(event.get_class()))
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			GLog.info("🖱️ LEFT CLICK on " + node_id)
			
			if not is_interactive:
				GLog.info("❌ Node " + node_id + " not interactive")
				return
			
			# Play selection animation
			play_select_animation()
			
			# Emit the click signal
			GLog.info("✅ EMITTING click signal: " + node_id)
			node_clicked.emit(node_id, event)

func _on_mouse_entered():
	"""Handle mouse hover enter"""
	GLog.debug("🖱️ HOVER: " + node_id)
	
	node_hovered.emit(node_id)
	
	# Visual feedback
	if is_interactive:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		# Hover animation started

func _on_mouse_exited():
	"""Handle mouse hover exit"""
	GLog.debug("🖱️ UNHOVER: " + node_id)
	
	node_unhovered.emit()
	
	# Reset visual feedback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	# Unhover animation started

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
