extends Control
class_name CardUI

## UI card component for deck management and other UI contexts
## This is a Control-based alternative to the Area2D Card scene

@export var card_data: CardData

# Selection state
var is_selected: bool = false

# Signals
signal card_clicked(card_ui: CardUI)

# Node references (set in _ready)
@onready var card_background: ColorRect = $CardBackground
@onready var card_border: ColorRect = $CardBorder
@onready var card_inner: ColorRect = $CardInner
@onready var type_symbol: Label = $TypeSymbol
@onready var card_name_label: Label = $CardInfo/CardName
@onready var card_handling_label: Label = $CardInfo/CardInfoContainer/CardHandling
@onready var description_label: RichTextLabel = $CardInfo/CardInfoContainer/Description
@onready var sanity_cost_label: Label = $CardInfo/CardInfoContainer/SanityCost
@onready var energy_cost_label: Label = $CardInfo/CardInfoContainer/EnergyCost
@onready var click_button: Button = $ClickButton

func _ready():
	# Connect click button
	if click_button:
		click_button.pressed.connect(_on_card_clicked)

	# Setup visuals if card_data is already set
	if card_data:
		setup_card_visuals()

func set_card_data(data: CardData) -> void:
	"""Set the card data and update visuals"""
	card_data = data
	if is_node_ready():
		setup_card_visuals()

func setup_card_visuals() -> void:
	"""Update all visual elements based on card_data"""
	if not card_data:
		return

	# Set card name
	if card_name_label:
		card_name_label.text = card_data.card_name
		card_name_label.add_theme_color_override("font_color", Color.BLACK)

	# Set type symbol
	if type_symbol:
		var symbol = CardTypeUtils.get_card_symbol(card_data.card_type)
		type_symbol.text = symbol

	# Set card colors based on type
	var type_color = CardTypeUtils.get_card_color(card_data.card_type)
	if card_border:
		card_border.color = type_color
	if card_background:
		card_background.color = Color.WHITE
	if card_inner:
		card_inner.color = Color(0.95, 0.93, 0.9, 1)  # Cream/off-white

	# Set energy cost
	if energy_cost_label:
		energy_cost_label.text = str(card_data.energy_cost)
		energy_cost_label.add_theme_color_override("font_color", Color(0, 0.5, 1, 1))  # Blue

	# Set description
	if description_label:
		var description_text = card_data.get_effect_descriptions("\n")
		description_label.text = description_text
		description_label.add_theme_color_override("default_color", Color.BLACK)
		description_label.visible = true
		description_label.fit_content = true

	# Set card handling info
	if card_handling_label:
		var handling_text = format_card_handling()
		card_handling_label.text = handling_text
		card_handling_label.visible = handling_text.length() > 0

		if handling_text.length() > 0:
			card_handling_label.add_theme_font_size_override("font_size", 10)
			card_handling_label.add_theme_color_override("font_color", Color.ORANGE)

	# Set sanity cost info
	if sanity_cost_label:
		if card_data.sanity_cost > 0:
			sanity_cost_label.text = "Sanity: %d" % card_data.sanity_cost
			sanity_cost_label.visible = true
			sanity_cost_label.add_theme_font_size_override("font_size", 10)
			sanity_cost_label.add_theme_color_override("font_color", Color.PURPLE)
		else:
			sanity_cost_label.visible = false

func format_card_handling() -> String:
	"""Format card handling text (Exhaust, Ethereal, etc.)"""
	# Use handling string directly - no theme translation needed
	var handling = card_data.card_handling
	return handling if handling != "Standard" else ""

func set_selected(selected: bool) -> void:
	"""Update visual state based on selection"""
	is_selected = selected
	if is_selected:
		# Yellow tint for selection
		modulate = Color(1, 1, 0.7, 1)
	else:
		# Normal appearance
		modulate = Color(1, 1, 1, 1)

func _on_card_clicked() -> void:
	"""Handle card click"""
	card_clicked.emit(self)
