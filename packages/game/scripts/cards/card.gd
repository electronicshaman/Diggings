extends Area2D
class_name Card

## Card - Gameplay card component (Area2D)
##
## This is the Area2D-based card used in active gameplay (hand, battlefield).
## Use this for:
## - Cards in player/enemy hands during combat
## - Cards on the battlefield
## - Interactive cards that need collision detection
##
## For UI contexts (deck management, shops, rewards), use CardUI instead.
## CardUI is a Control-based component optimized for UI layouts.
##
## Key features:
## - Area2D collision for hover/click detection
## - Z-index management for hover effects
## - Curio-aware cost display with caching
## - EventBus integration for MVC compliance
## - Quick draw highlighting support

# Preload CardTypeUtils for card type utilities
const CardTypeUtils = preload("res://scripts/config/card_type_utils.gd")

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Color constants
const ENERGY_COST_COLOR_NORMAL := Color(0, 0.5, 1, 1)  # Blue
const ENERGY_COST_COLOR_MODIFIED := Color.LIME
const ENERGY_COST_COLOR_INSUFFICIENT := Color.DARK_RED
const CARD_BACK_COLOR := Color(0.3, 0.2, 0.1, 1)
const CARD_BACK_INNER_COLOR := Color(0.4, 0.3, 0.2, 1)
const QUICK_DRAW_HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.0)
const CARD_UNPLAYABLE_TINT := Color(0.6, 0.6, 0.6, 1)

# Font sizes
const CARD_HANDLING_FONT_SIZE := 10
const SANITY_COST_FONT_SIZE := 10

# Z-index constants
const Z_INDEX_HOVER := 10

@export var card_data: CardData
@export var card_instance: CardInstance

# Node references with corrected paths
# Note: Some nodes may not exist in card_back.tscn variant, so we use get_node_or_null
@onready var card_background: ColorRect = $CardBackground
@onready var card_border: ColorRect = $CardBorder
@onready var card_inner: Node = $CardInner  # Can be ColorRect or TextureRect depending on scene variant
@onready var type_symbol: Label = get_node_or_null("CardContent/Header/TypeSymbol")
@onready var card_name_label: Label = get_node_or_null("CardContent/Header/CardName")
@onready var card_handling_label: Label = get_node_or_null("CardContent/CardInfo/CardHandling")
@onready var description_label: RichTextLabel = get_node_or_null("CardContent/CardInfo/Description")
@onready var energy_cost_label: Label = get_node_or_null("CardContent/CardInfo/HBoxContainer/EnergyCost")
@onready var sanity_cost_label: Label = get_node_or_null("CardContent/CardInfo/HBoxContainer/SanityCost")
@onready var card_image: Node = get_node_or_null("CardImage")  # May not exist in card_back variant
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

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

func _ready() -> void:
	original_scale = scale

	# Enable input detection
	monitoring = true
	monitorable = true

	# Wait for node to be ready before setting up visuals
	if card_data:
		setup_card_visuals()

	setup_hover_effects()

	# Listen for curio changes to refresh visuals
	EventBus.connect_safe("curio_acquired", _on_curio_changed)
	EventBus.connect_safe("curio_removed", _on_curio_changed)
	EventBus.connect_safe("curio_stack_changed", _on_curio_changed)

# Accept either CardInstance or CardData and configure this node
func set_card(card: Variant) -> void:
	if not card:
		GLog.error("set_card called with null card", "Card")
		return

	if card is CardInstance:
		card_instance = card
		card_data = card.card_data
		if DEBUG_ENABLED:
			GLog.debug("Card set from CardInstance: %s" % card_data.card_name, "Card")
	elif card is CardData:
		card_data = card
		card_instance = null
		if DEBUG_ENABLED:
			GLog.debug("Card set from CardData: %s" % card_data.card_name, "Card")
	else:
		GLog.error("set_card called with invalid type: %s" % type_string(typeof(card)), "Card")
		return

	if is_node_ready():
		setup_card_visuals()

func get_card_instance_or_null() -> CardInstance:
	return card_instance if card_instance else null

# Determine if this is a player card (for curio effect application)
func _is_player_card() -> bool:
	if card_instance:
		return card_instance.owner == CardInstance.Owner.PLAYER
	return true  # Default for preview/shop cards

func _get_display_cost() -> Dictionary:
	"""Get display cost - delegates to CardInstance if available"""
	# Prefer CardInstance (has owner context for curio calculations)
	if card_instance and card_instance.has_method("get_display_energy_cost"):
		return card_instance.get_display_energy_cost()

	# Fallback for CardData-only cards (shops, previews)
	# These are typically player cards so assume curio bonuses apply
	if card_data and CurioManager:
		var base_cost: int = card_data.energy_cost
		var mods: Dictionary = CurioManager.calculate_card_modifications(card_data, true)
		var cost_reduction: int = mods.get("cost", 0)
		if cost_reduction != 0:
			var display_cost = max(0, base_cost + cost_reduction)
			return {"cost": display_cost, "modified": true}

	# No curio modifications
	var base = card_data.energy_cost if card_data else 0
	return {"cost": base, "modified": false}

func _on_curio_changed(_curio: Resource = null, _stacks: int = 0) -> void:
	"""Refresh visuals when curios change"""
	if is_node_ready():
		_update_dynamic_visuals()

func setup_card_visuals() -> void:
	"""Initial setup - called once in _ready or set_card"""
	if not card_data:
		if DEBUG_ENABLED:
			GLog.warn("setup_card_visuals called but card_data is null", "Card")
		return

	if not is_node_ready():
		if DEBUG_ENABLED:
			GLog.warn("setup_card_visuals called before _ready()", "Card")
		return

	_update_static_visuals()
	_update_dynamic_visuals()

func _update_static_visuals() -> void:
	"""Update visuals that don't change during combat (name, type, description, handling)"""
	if not is_node_ready() or not card_data:
		return

	# Card name
	if card_name_label:
		card_name_label.text = card_data.card_name

	# Type symbol and colors
	if type_symbol:
		type_symbol.text = CardTypeUtils.get_card_symbol(card_data.card_type)

	var type_color: Color = CardTypeUtils.get_card_color(card_data.card_type)
	if card_border:
		card_border.color = type_color
		original_border_color = type_color
	if card_background:
		card_background.color = Color.WHITE

	# Description
	if description_label:
		var description_text: String = format_description()
		description_label.text = description_text
		description_label.visible = true
		description_label.fit_content = true

	# Card handling
	if card_handling_label:
		var handling_text: String = format_card_handling()
		card_handling_label.text = handling_text
		card_handling_label.visible = not handling_text.is_empty()

		if not handling_text.is_empty():
			card_handling_label.add_theme_font_size_override("font_size", CARD_HANDLING_FONT_SIZE)
			card_handling_label.add_theme_color_override("font_color", Color.ORANGE)
			card_handling_label.add_theme_color_override("font_shadow_color", Color.BLACK)
			card_handling_label.add_theme_constant_override("shadow_offset_x", 1)
			card_handling_label.add_theme_constant_override("shadow_offset_y", 1)

	# Sanity cost
	_update_sanity_cost_display()

	# Hide card image placeholder
	if card_image:
		card_image.visible = false

func _update_dynamic_visuals() -> void:
	"""Update visuals that change during combat (energy cost, etc)"""
	if not is_node_ready():
		return

	_update_energy_cost_display()

func _update_energy_cost_display() -> void:
	"""Update energy cost label with curio modifications"""
	if not energy_cost_label or not card_data:
		return

	var cost_data: Dictionary = _get_display_cost()
	energy_cost_label.text = str(cost_data.cost)

	# Color based on modification state (will be overridden by update_energy_status if needed)
	if cost_data.modified:
		energy_cost_label.add_theme_color_override("font_color", ENERGY_COST_COLOR_MODIFIED)
	else:
		energy_cost_label.add_theme_color_override("font_color", ENERGY_COST_COLOR_NORMAL)

func _update_sanity_cost_display() -> void:
	"""Update sanity cost display"""
	if not sanity_cost_label or not card_data:
		return

	if card_data.sanity_cost > 0:
		sanity_cost_label.text = "Sanity: %d" % card_data.sanity_cost
		sanity_cost_label.visible = true
		sanity_cost_label.add_theme_font_size_override("font_size", SANITY_COST_FONT_SIZE)
		sanity_cost_label.add_theme_color_override("font_color", Color.PURPLE)
		sanity_cost_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	else:
		sanity_cost_label.visible = false

func setup_hover_effects() -> void:
	"""Setup mouse hover effects and click detection"""
	# Connect mouse enter/exit signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Connect Area2D input_event signal - backup click handler
	input_event.connect(_on_card_clicked)

	# Add invisible button for reliable clicking
	add_click_button()

func add_click_button() -> void:
	"""Add an invisible button for reliable click detection"""
	# Check if button already exists
	if has_node("ClickButton"):
		return

	var button = Button.new()
	button.name = "ClickButton"
	button.flat = true
	button.modulate = Color.TRANSPARENT
	button.mouse_filter = Control.MOUSE_FILTER_PASS

	# Position button for NEW layout (starts at 0,0, extends to 300,420)
	button.position = Vector2(0, 0)
	button.size = Vector2(300, 420)

	add_child(button)
	button.pressed.connect(_on_button_clicked)

func _on_button_clicked() -> void:
	"""Handle button click"""
	if not card_data:
		GLog.error("Card clicked but has no card_data! (name: %s)" % name, "Card")
		return

	if DEBUG_ENABLED:
		GLog.debug("Card clicked (via button): %s" % card_data.card_name, "Card")

	# Emit via EventBus for MVC compliance
	EventBus.card_played.emit(self)

	# Also emit local signal for backward compatibility
	card_played.emit(self)

func _on_mouse_entered() -> void:
	"""Handle mouse entering card area"""
	is_hovering = true

	# Store original z-index and bring to front
	original_z_index = z_index
	z_index = Z_INDEX_HOVER

func _on_mouse_exited() -> void:
	"""Handle mouse leaving card area"""
	is_hovering = false

	# Return to original z-index (preserves hand positioning)
	z_index = original_z_index

func _on_card_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Handle Area2D input events - backup click handler"""
	if not event is InputEventMouseButton:
		return

	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not card_data:
		GLog.error("Card clicked but has no card_data! (name: %s)" % name, "Card")
		return

	if DEBUG_ENABLED:
		GLog.debug("Card clicked (via Area2D): %s" % card_data.card_name, "Card")

	# Emit via EventBus for MVC compliance
	EventBus.card_played.emit(self)

	# Also emit local signal for backward compatibility
	card_played.emit(self)


func format_description() -> String:
	"""Format card description text (prefers CardInstance for context-aware descriptions)"""
	# Prefer CardInstance for context-aware descriptions (handles conditionals)
	# Fall back to CardData for basic effect descriptions
	if card_instance and card_instance.has_method("get_effect_descriptions"):
		return card_instance.get_effect_descriptions("\n")
	elif card_data:
		return card_data.get_effect_descriptions("\n")
	else:
		return ""

func format_card_handling() -> String:
	"""Format card handling text (Exhaust, Ethereal, etc.)"""
	if not card_data:
		return ""
	# Use handling string directly - no theme translation needed
	var handling: String = card_data.card_handling
	return handling if handling != "Standard" else ""

func set_selected(selected: bool) -> void:
	"""Update selection state and visuals"""
	is_selected = selected
	update_visual_state()

func update_visual_state() -> void:
	"""Update visual state based on selection"""
	if not card_data or not card_background:
		return

	var base_color: Color = CardTypeUtils.get_card_color(card_data.card_type)
	if is_selected:
		# Highlight selected cards
		card_background.color = base_color.lightened(0.3)
		position.y -= 10  # Lift selected cards slightly
	else:
		# Normal appearance
		card_background.color = base_color
		position.y += 10 if position.y < 500 else 0  # Reset position if lifted

func set_quick_draw_highlight(enabled: bool) -> void:
	"""Highlight or unhighlight this card for quick draw/first turn bonus"""
	if not card_border:
		return

	if enabled:
		# Store original color if not already highlighted
		if not is_quick_draw_highlighted:
			original_border_color = card_border.color
		# Apply bright gold highlight
		card_border.color = QUICK_DRAW_HIGHLIGHT_COLOR
		is_quick_draw_highlighted = true
	else:
		# Restore original type-based border color
		if card_data:
			var type_color: Color = CardTypeUtils.get_card_color(card_data.card_type)
			card_border.color = type_color
		is_quick_draw_highlighted = false

func show_as_card_back() -> void:
	"""Display this card as a card back (hide information)"""
	# Hide card content (name, description, etc.)
	if has_node("CardContent"):
		$CardContent.visible = false

	# Show card back styling
	if card_background:
		card_background.color = CARD_BACK_COLOR

	# card_inner might be TextureRect (card_back.tscn) or ColorRect (card.tscn)
	if card_inner and card_inner is ColorRect:
		card_inner.color = CARD_BACK_INNER_COLOR

	# Optional: Add card back pattern or text
	if type_symbol:
		type_symbol.text = "?"
		type_symbol.visible = true

func update_energy_status(current_energy: int) -> void:
	"""Update card visual state based on available energy"""
	if not energy_cost_label or not card_data:
		return

	var cost_data: Dictionary = _get_display_cost()
	var display_cost: int = cost_data.cost
	var cost_modified: bool = cost_data.modified

	# Update cost text (in case it wasn't set yet)
	energy_cost_label.text = str(display_cost)

	# Update color based on playability
	if current_energy < display_cost:
		energy_cost_label.add_theme_color_override("font_color", ENERGY_COST_COLOR_INSUFFICIENT)
		modulate = CARD_UNPLAYABLE_TINT
	else:
		modulate = Color.WHITE
		if cost_modified:
			energy_cost_label.add_theme_color_override("font_color", ENERGY_COST_COLOR_MODIFIED)
		else:
			energy_cost_label.add_theme_color_override("font_color", ENERGY_COST_COLOR_NORMAL)
