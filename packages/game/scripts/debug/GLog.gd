extends Node

## Global Logging System (gLog)
## 
## Usage: GLog.log("Your message", GLog.Level.DEBUG)
## Or simply: GLog.debug("Your message")
##
## Enable/disable logging by setting debug_enabled = false

# Global debug toggle - set this to false to disable all logging
var debug_enabled: bool = true

# Log levels for filtering
enum Level {
	TRACE,   # Very detailed debugging info
	DEBUG,   # General debugging info
	INFO,    # General information
	WARN,    # Warning messages
	ERROR,   # Error messages
	CRITICAL # Critical errors only
}

# Current minimum log level (logs below this level are ignored)
var min_log_level: Level = Level.DEBUG

# Color coding for different log levels
var level_colors := {
	Level.TRACE: Color.DARK_GRAY,
	Level.DEBUG: Color.CYAN,
	Level.INFO: Color.WHITE,
	Level.WARN: Color.YELLOW,
	Level.ERROR: Color.ORANGE,
	Level.CRITICAL: Color.RED
}

# Level names for display
var level_names := {
	Level.TRACE: "TRACE",
	Level.DEBUG: "DEBUG", 
	Level.INFO: "INFO",
	Level.WARN: "WARN",
	Level.ERROR: "ERROR",
	Level.CRITICAL: "CRITICAL"
}

# Per-file debug toggles (for fine-grained control)
var file_debug_toggles := {}

## Main logging function
func write_log(message: String, level: Level = Level.INFO, source: String = "") -> void:
	# Early exit if logging disabled globally
	if not debug_enabled:
		return
	
	# Early exit if below minimum log level
	if level < min_log_level:
		return
	
	# Auto-detect source file if not provided
	var detected_source = source
	if detected_source == "":
		var stack = get_stack()
		if stack.size() >= 2:
			var caller = stack[1]
			var source_parts = caller.source.split("/")
			detected_source = source_parts[-1].replace(".gd", "")
	
	# Check per-file toggle
	if file_debug_toggles.has(detected_source):
		if not file_debug_toggles[detected_source]:
			return
	
	# Check if calling file has DEBUG_ENABLED const set to false
	if _is_debug_disabled_in_source():
		return
	
	# Format the log message
	var timestamp = Time.get_datetime_string_from_system()
	var level_name = level_names.get(level, "UNKNOWN")
	var color = level_colors.get(level, Color.WHITE)
	
	var formatted_message: String
	if detected_source != "":
		formatted_message = "[%s] [%s] [%s] %s" % [timestamp.split("T")[1].split(".")[0], level_name, detected_source, message]
	else:
		formatted_message = "[%s] [%s] %s" % [timestamp.split("T")[1].split(".")[0], level_name, message]
	
	# Print with color if supported
	print_rich("[color=%s]%s[/color]" % [color.to_html(), formatted_message])

## Check if the calling file has DEBUG_ENABLED = false
func _is_debug_disabled_in_source() -> bool:
	var stack = get_stack()
	if stack.size() < 2:
		return false
	
	var caller = stack[1]
	var source_path = caller.source
	
	# Try to load the script and check for DEBUG_ENABLED constant
	if ResourceLoader.exists(source_path):
		var script = load(source_path)
		if script is GDScript:
			# Check if the script has a DEBUG_ENABLED constant set to false
			var script_constants = script.get_script_constant_map()
			if script_constants.has("DEBUG_ENABLED"):
				return script_constants["DEBUG_ENABLED"] == false
	
	# Default to enabled if we can't determine
	return false

## Convenience functions for different log levels
func trace(message: String, source: String = "") -> void:
	write_log(message, Level.TRACE, source)

func debug(message: String, source: String = "") -> void:
	write_log(message, Level.DEBUG, source)

func info(message: String, source: String = "") -> void:
	write_log(message, Level.INFO, source)

func warn(message: String, source: String = "") -> void:
	write_log(message, Level.WARN, source)

func error(message: String, source: String = "") -> void:
	write_log(message, Level.ERROR, source)

func critical(message: String, source: String = "") -> void:
	write_log(message, Level.CRITICAL, source)

## File-specific debug control
func set_file_debug(file_name: String, enabled: bool) -> void:
	file_debug_toggles[file_name] = enabled
	debug("File debug toggled: %s = %s" % [file_name, enabled], "GLog")

func get_file_debug(file_name: String) -> bool:
	return file_debug_toggles.get(file_name, true)

## Global debug control
func enable_debug() -> void:
	debug_enabled = true
	info("Global debug enabled", "GLog")

func disable_debug() -> void:
	info("Global debug disabled", "GLog")
	debug_enabled = false

func set_min_level(level: Level) -> void:
	min_log_level = level
	info("Minimum log level set to: %s" % level_names[level], "GLog")

## Utility function to log with automatic source detection
func log_from(message: String, level: Level = Level.INFO) -> void:
	var stack = get_stack()
	var source = ""
	
	if stack.size() >= 2:
		# Get the calling function's source
		var caller = stack[1]
		var source_parts = caller.source.split("/")
		source = source_parts[-1].replace(".gd", "")
		if caller.function != "":
			source += ":" + caller.function
	
	write_log(message, level, source)

## Debug helpers for common patterns
func log_method_enter(method_name: String, params: Array = []) -> void:
	var stack = get_stack()
	var source = ""
	if stack.size() >= 2:
		var caller = stack[1]
		var source_parts = caller.source.split("/")
		source = source_parts[-1].replace(".gd", "")
	
	var param_str = ""
	if not params.is_empty():
		param_str = " with params: " + str(params)
	
	trace("→ Entering %s%s" % [method_name, param_str], source)

func log_method_exit(method_name: String, return_value = null) -> void:
	var stack = get_stack()
	var source = ""
	if stack.size() >= 2:
		var caller = stack[1]
		var source_parts = caller.source.split("/")
		source = source_parts[-1].replace(".gd", "")
	
	var return_str = ""
	if return_value != null:
		return_str = " returning: " + str(return_value)
	
	trace("← Exiting %s%s" % [method_name, return_str], source)
