extends Control
class_name MapController

@onready var view_deck_button = $UIContainer/HeaderPanel/HeaderContent/ViewDeckButton
@onready var start_node = $UIContainer/MapScrollContainer/MapLayers/Layer1/StartNode
@onready var shop_node = $UIContainer/MapScrollContainer/MapLayers/Layer2/ShopNode
@onready var event_node = $UIContainer/MapScrollContainer/MapLayers/Layer2/EventNode

func _ready():
	setup_button_connections()

func setup_button_connections():
	view_deck_button.pressed.connect(_on_view_deck_pressed)
	start_node.pressed.connect(_on_combat_node_pressed)
	shop_node.pressed.connect(_on_shop_node_pressed)
	event_node.pressed.connect(_on_event_node_pressed)

func _on_view_deck_pressed():
	GLog.info("View Deck button pressed")
	SceneManager.load_scene_by_name("deck_viewer")

func _on_combat_node_pressed():
	GLog.info("Combat node pressed")
	SceneManager.load_scene_by_name("main_game")

func _on_shop_node_pressed():
	GLog.info("Shop node pressed")
	SceneManager.load_scene_by_name("shop")

func _on_event_node_pressed():
	GLog.info("Event node pressed")
	SceneManager.load_scene_by_name("event")