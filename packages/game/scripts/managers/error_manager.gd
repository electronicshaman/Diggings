class_name ErrorManager
extends RefCounted

## ErrorManager - Centralized error tracking and monitoring
##
## Tracks errors across the application with categorization,
## rate limiting, and critical error detection.

const DEBUG_ENABLED: bool = true
const MAX_CRITICAL_ERRORS: int = 10
const ERROR_RATE_WINDOW: float = 60.0  # Track errors per minute

var _error_count: int = 0
var _last_error_time: float = 0.0
var _critical_errors: Array[String] = []
var _error_timestamps: Array[float] = []
var _error_categories: Dictionary = {}  # category -> count

## Record an error with optional categorization
func record_error(error_message: String, category: String = "general") -> void:
	_error_count += 1
	_last_error_time = Time.get_ticks_msec() / 1000.0
	_error_timestamps.append(_last_error_time)
	
	# Track by category
	if not _error_categories.has(category):
		_error_categories[category] = 0
	_error_categories[category] += 1
	
	# Clean old timestamps for rate calculation
	_clean_old_timestamps()
	
	# Track critical errors
	if _is_critical_error(error_message):
		_critical_errors.append(error_message)
		
		# Limit critical error history
		if _critical_errors.size() > MAX_CRITICAL_ERRORS:
			_critical_errors.pop_front()
		
		GLog.error("CRITICAL ERROR #%d: %s" % [_error_count, error_message])
	else:
		GLog.error("Error #%d [%s]: %s" % [_error_count, category, error_message])

## Check if an error is critical based on keywords
func _is_critical_error(error_message: String) -> bool:
	var critical_keywords = ["critical", "fatal", "crash", "corrupt", "invalid_data"]
	var message_lower = error_message.to_lower()
	
	for keyword in critical_keywords:
		if message_lower.contains(keyword):
			return true
	
	return false

## Clean timestamps older than the rate window
func _clean_old_timestamps() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var cutoff_time = current_time - ERROR_RATE_WINDOW
	
	while _error_timestamps.size() > 0 and _error_timestamps[0] < cutoff_time:
		_error_timestamps.pop_front()

## Get current error rate (errors per minute)
func get_error_rate() -> float:
	_clean_old_timestamps()
	return _error_timestamps.size()

## Check if error rate is above threshold
func is_error_rate_high(threshold: float = 10.0) -> bool:
	return get_error_rate() > threshold

## Get comprehensive error diagnostics
func get_diagnostics() -> Dictionary:
	return {
		"total_errors": _error_count,
		"last_error_time": _last_error_time,
		"critical_errors": _critical_errors.duplicate(),
		"error_rate_per_minute": get_error_rate(),
		"categories": _error_categories.duplicate(),
		"is_rate_high": is_error_rate_high()
	}

## Clear all error history (useful for testing)
func clear_history() -> void:
	_error_count = 0
	_last_error_time = 0.0
	_critical_errors.clear()
	_error_timestamps.clear()
	_error_categories.clear()
	GLog.debug("ErrorManager: History cleared")

## Get errors by category
func get_errors_by_category(category: String) -> int:
	return _error_categories.get(category, 0)

## Get most frequent error category
func get_most_frequent_category() -> String:
	var max_count = 0
	var max_category = ""
	
	for category in _error_categories:
		if _error_categories[category] > max_count:
			max_count = _error_categories[category]
			max_category = category
	
	return max_category