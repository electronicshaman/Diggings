extends Node

const DEBUG_ENABLED: bool = true

# Modal queue for handling multiple modals
var modal_queue: Array[Dictionary] = []
var current_modal: Control = null
var modal_layer: CanvasLayer = null

# Modal scene paths
const MODAL_SCENES = {
	"encounter_preview": "res://scenes/ui/modals/encounter_preview_modal.tscn",
	"reward_summary": "res://scenes/ui/modals/reward_summary_modal.tscn", 
	"notification": "res://scenes/ui/modals/notification_modal.tscn"
}

func _ready() -> void:
	GLog.debug("ModalManager initialized")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	_setup_modal_layer()
	
	# Connect to EventBus for modal requests
	if EventBus.has_signal("modal_requested"):
		EventBus.connect_safe("modal_requested", Callable(self, "_on_modal_requested"))

func _setup_modal_layer() -> void:
	"""Create a high-priority canvas layer for modals"""
	modal_layer = CanvasLayer.new()
	modal_layer.name = "ModalLayer" 
	modal_layer.layer = 999  # Highest priority to appear above everything
	add_child(modal_layer)
	GLog.debug("Modal layer created with priority 999")

func show_modal(modal_type: String, data: Dictionary = {}) -> void:
	"""Queue a modal to be displayed"""
	var modal_request = {
		"type": modal_type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	modal_queue.append(modal_request)
	GLog.debug("Queued modal: %s (queue size: %d)" % [modal_type, modal_queue.size()])
	
	# Process queue if no modal is currently active
	if not current_modal:
		_process_next_modal()

func _process_next_modal() -> void:
	"""Process the next modal in the queue"""
	if modal_queue.is_empty():
		GLog.debug("Modal queue empty")
		return
		
	if current_modal:
		GLog.warn("Attempted to process modal while one is active")
		return
	
	var modal_request = modal_queue.pop_front()
	var modal_type = modal_request.type
	var modal_data = modal_request.data
	
	GLog.debug("Processing modal: %s" % modal_type)
	
	# Load and instantiate the modal scene
	if not MODAL_SCENES.has(modal_type):
		GLog.error("Unknown modal type: %s" % modal_type)
		_process_next_modal()  # Try next modal
		return
	
	var modal_scene_path = MODAL_SCENES[modal_type]
	var modal_scene = load(modal_scene_path)
	
	if not modal_scene:
		GLog.error("Failed to load modal scene: %s" % modal_scene_path)
		_process_next_modal()  # Try next modal
		return
	
	current_modal = modal_scene.instantiate()
	modal_layer.add_child(current_modal)
	
	# Initialize modal with data
	if current_modal.has_method("initialize"):
		current_modal.initialize(modal_data)
	
	# Connect modal completion signal
	if current_modal.has_signal("modal_completed"):
		current_modal.connect("modal_completed", Callable(self, "_on_modal_completed"))
	
	# Pause the scene tree for modal interaction
	get_tree().paused = true
	
	# Emit EventBus signal
	EventBus.emit_signal("modal_opened", modal_type)
	GLog.debug("Modal opened: %s" % modal_type)

func _on_modal_completed(result: Variant = null) -> void:
	"""Handle when a modal is completed"""
	if not current_modal:
		GLog.warn("Modal completed but no current modal")
		return
	
	var modal_type = _get_modal_type(current_modal)
	GLog.debug("Modal completed: %s with result: %s" % [modal_type, str(result)])
	
	# Emit EventBus signal
	EventBus.emit_signal("modal_closed", modal_type, result)
	
	# Clean up current modal
	current_modal.queue_free()
	current_modal = null
	
	# Resume the scene tree
	get_tree().paused = false
	
	# Process next modal in queue
	await get_tree().process_frame  # Wait one frame for cleanup
	_process_next_modal()

func _get_modal_type(modal_node: Control) -> String:
	"""Get the modal type from a modal node"""
	var scene_path = modal_node.scene_file_path
	for type in MODAL_SCENES:
		if MODAL_SCENES[type] == scene_path:
			return type
	return "unknown"

func hide_current_modal(result: Variant = null) -> void:
	"""Force hide the current modal"""
	if current_modal:
		_on_modal_completed(result)

func clear_modal_queue() -> void:
	"""Clear all queued modals"""
	var cleared_count = modal_queue.size()
	modal_queue.clear()
	GLog.debug("Cleared %d modals from queue" % cleared_count)

func is_modal_active() -> bool:
	"""Check if a modal is currently displayed"""
	return current_modal != null

func get_queue_size() -> int:
	"""Get the number of modals in queue"""
	return modal_queue.size()

# EventBus signal handlers
func _on_modal_requested(modal_type: String, data: Dictionary = {}) -> void:
	"""Handle modal requests from EventBus"""
	show_modal(modal_type, data)

# Convenience methods for common modals
func show_encounter_preview(encounter_instance: Resource) -> void:
	"""Show encounter preview modal"""
	show_modal("encounter_preview", {"encounter": encounter_instance})

func show_reward_summary(rewards: Dictionary) -> void:
	"""Show reward summary modal"""
	show_modal("reward_summary", rewards)

func show_notification(title: String, message: String, button_text: String = "OK") -> void:
	"""Show simple notification modal"""
	show_modal("notification", {
		"title": title,
		"message": message, 
		"button_text": button_text
	})