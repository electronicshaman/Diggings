extends Node
class_name EffectProcessor

const DEBUG_ENABLED: bool = true

# Safe logging helper to handle cases where GLog might not be available
func _safe_log(level: String, message: String) -> void:
	if GLog and is_instance_valid(GLog):
		match level:
			"debug":
				if DEBUG_ENABLED:
					GLog.debug(message)
			"info":
				GLog.info(message)
			"warn":
				GLog.warn(message)
			"error":
				GLog.error(message)
			"trace":
				if DEBUG_ENABLED and GLog.min_log_level <= GLog.Level.TRACE:
					GLog.trace(message)
	else:
		# Fallback to print if GLog is not available
		if DEBUG_ENABLED or level in ["warn", "error"]:
			print("[%s] %s" % [level.to_upper(), message])

# Signals for effect processing events
signal effect_executed(effect: HandlerBase, result: HandlerResult, context: HandlerContext)
signal effect_failed(effect: HandlerBase, reason: String, context: HandlerContext)
signal batch_completed(results: Array[HandlerResult])

# Enhanced debugging signals
signal performance_warning(operation: String, duration_ms: int, threshold_ms: int)
signal debug_trace_updated(trace_data: Dictionary)

# Error handling and recovery signals
signal error_recovered(error_type: String, recovery_action: String, context: Dictionary)
signal critical_error_detected(error_type: String, error_details: Dictionary)
signal validation_error(validation_type: String, error_message: String, object_info: Dictionary)

# Deterministic processing configuration
var _deterministic_mode: bool = true  # Ensures consistent results for identical inputs
var _sort_effects_by_id: bool = true  # Sort effects by ID to ensure consistent processing order
var _validate_deterministic_results: bool = false  # When true, validates that repeated processing produces identical results

# Context cache for performance optimization
var _context_cache: Dictionary = {}
var _cache_enabled: bool = true
var _context_cache_max_size: int = 100
var _context_cache_ttl_ms: int = 30000  # 30 seconds TTL for cached contexts

# Enhanced context performance monitoring
var _context_performance_stats: Dictionary = {
	"contexts_created": 0,
	"contexts_reused": 0,
	"cache_hits": 0,
	"cache_misses": 0,
	"cache_evictions": 0,
	"total_creation_time_ms": 0,
	"total_curio_lookup_time_ms": 0,
	"average_creation_time_ms": 0.0,
	"peak_creation_time_ms": 0,
	"contexts_pooled": 0,
	"pool_reuse_rate": 0.0
}

# Batch processing optimization settings
var _batch_optimization_enabled: bool = true
var _batch_size_threshold: int = 5  # Minimum batch size to trigger optimizations
var _object_pool_enabled: bool = true
var _validation_cache_enabled: bool = true

# Object pools for performance optimization
var _effect_result_pool: Array[HandlerResult] = []
var _context_pool: Array[HandlerContext] = []
var _max_pool_size: int = 50
var _pool_warmup_size: int = 10  # Pre-allocate this many objects
var _pool_shrink_threshold: int = 75  # Shrink pool when it exceeds this size

# Validation cache to avoid redundant checks
var _validation_cache: Dictionary = {}
var _validation_cache_max_size: int = 100

# Batch processing performance metrics
var _batch_performance_stats: Dictionary = {
	"batches_optimized": 0,
	"objects_pooled": 0,
	"validation_cache_hits": 0,
	"allocation_savings": 0,
	"processing_time_saved_ms": 0
}

# Error handling and recovery configuration
var _error_recovery_enabled: bool = true
var _max_recovery_attempts: int = 3
var _recovery_attempt_counts: Dictionary = {}
var _critical_error_threshold: int = 5
var _critical_errors_count: int = 0

# Edge case handling configuration
var _strict_validation: bool = false  # When true, fails fast on any validation error
var _allow_partial_batch_success: bool = true  # When true, continues processing batch even if some effects fail
var _null_safety_enabled: bool = true  # Enhanced null checking and safe fallbacks
var _malformed_data_recovery: bool = true  # Attempt to recover from malformed effect data

# Enhanced processing statistics and performance monitoring
var _stats: Dictionary = {
	"total_effects_processed": 0,
	"successful_effects": 0,
	"failed_effects": 0,
	"batch_count": 0,
	"total_processing_time_ms": 0,
	"average_effect_time_ms": 0.0,
	"slowest_effect_time_ms": 0,
	"fastest_effect_time_ms": 999999,
	"cache_hits": 0,
	"cache_misses": 0,
	"validation_failures": 0,
	"context_creation_time_ms": 0,
	"error_recoveries": 0,
	"critical_errors": 0,
	"malformed_data_encountered": 0,
	"null_safety_activations": 0,
	"edge_cases_handled": 0,
	"deterministic_validations_run": 0,
	"deterministic_validations_passed": 0,
	"effects_sorted_for_determinism": 0,
	"batch_optimizations_used": 0,
	"object_allocations_saved": 0,
	"validation_cache_hits": 0
}

# Performance monitoring thresholds
var _performance_thresholds: Dictionary = {
	"effect_processing_ms": 50,
	"batch_processing_ms": 200,
	"context_creation_ms": 10
}

# Debug trace system for detailed debugging
var _debug_trace_enabled: bool = false
var _debug_trace_buffer: Array[Dictionary] = []
var _max_trace_entries: int = 100

# Effect processing history for debugging
var _processing_history: Array[Dictionary] = []
var _max_history_entries: int = 50

## Process multiple effects in batch with performance optimizations
func process_effects(effects: Array[HandlerBase], context: HandlerContext) -> Array[HandlerResult]:
	var batch_start_time = Time.get_ticks_msec()
	var results: Array[HandlerResult] = []
	
	# Check if batch optimization should be applied
	var use_batch_optimization = _batch_optimization_enabled and effects.size() >= _batch_size_threshold
	
	if use_batch_optimization:
		return _process_effects_optimized(effects, context, batch_start_time)
	else:
		return _process_effects_standard(effects, context, batch_start_time)

## Optimized batch processing for large effect sets
func _process_effects_optimized(effects: Array[HandlerBase], context: HandlerContext, batch_start_time: int) -> Array[HandlerResult]:
	var results: Array[HandlerResult] = []
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Using optimized batch processing for %d effects" % effects.size())
	
	# Pre-allocate results array for better memory performance
	results.resize(effects.size())
	
	# Enhanced input validation with caching
	var validation_result = _validate_batch_inputs_cached(effects, context)
	if not validation_result.valid:
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Batch validation failed - %s" % validation_result.error_message)
		_stats.validation_failures += 1
		
		# Attempt recovery if enabled
		if _error_recovery_enabled and validation_result.recoverable:
			var recovery_result = _attempt_batch_recovery(effects, context, validation_result)
			if recovery_result.success:
				_safe_log("warn", "EffectProcessor: Batch validation recovered - %s" % recovery_result.recovery_action)
				_stats.error_recoveries += 1
				error_recovered.emit("batch_validation", recovery_result.recovery_action, {
					"original_error": validation_result.error_message,
					"effect_count": effects.size() if effects else 0
				})
				effects = recovery_result.recovered_effects as Array[HandlerBase]
				context = recovery_result.recovered_context
			else:
				_handle_critical_error("batch_validation_unrecoverable", {
					"error": validation_result.error_message,
					"recovery_attempted": true,
					"recovery_error": recovery_result.error_message
				})
				batch_completed.emit(results)
				return results
		else:
			_handle_critical_error("batch_validation_failed", {
				"error": validation_result.error_message,
				"recovery_enabled": _error_recovery_enabled
			})
			batch_completed.emit(results)
			return results
	
	# Ensure deterministic processing order if enabled
	var processing_effects = effects
	if _deterministic_mode and _sort_effects_by_id:
		processing_effects = _sort_effects_for_deterministic_processing(effects)
		if processing_effects != effects:
			_stats.effects_sorted_for_determinism += 1
	
	# Pre-validate all effects to avoid redundant checks during processing
	var effect_validations: Array[bool] = []
	if _validation_cache_enabled:
		effect_validations = _batch_validate_effects(processing_effects)
	
	# Batch process effects with optimizations
	var processed_count = 0
	var failed_count = 0
	var batch_processing_time = 0
	var critical_failures = 0
	
	for i in range(processing_effects.size()):
		var effect = processing_effects[i]
		var effect_start_time = Time.get_ticks_msec()
		
		# Use cached validation result if available
		var is_valid = true
		if _validation_cache_enabled and i < effect_validations.size():
			is_valid = effect_validations[i]
		else:
			is_valid = _validate_effect_for_processing(effect, i)
		
		if is_valid:
			# Get result from pool or create new one
			var result = _get_pooled_effect_result()
			result = _process_single_effect_optimized(effect, context, result)
			results[i] = result
			
			var effect_processing_time = Time.get_ticks_msec() - effect_start_time
			batch_processing_time += effect_processing_time
			
			_update_effect_performance_stats(effect_processing_time)
			
			if result.success:
				processed_count += 1
				_stats.successful_effects += 1
				effect_executed.emit(effect, result, context)
			else:
				failed_count += 1
				_stats.failed_effects += 1
				
				var is_critical = _is_critical_failure(result)
				if is_critical:
					critical_failures += 1
				
				var reason = _extract_failure_reason(result)
				effect_failed.emit(effect, reason, context)
				
				if not _allow_partial_batch_success and is_critical:
					_safe_log("error", "EffectProcessor: Aborting batch due to critical failure in effect %d" % i)
					break
		else:
			# Create failure result from pool
			var failure_result = _get_pooled_effect_result()
			failure_result.success = false
			failure_result.values_applied = {}
			var logs_array: Array[String] = ["Effect failed validation at index %d" % i]
			failure_result.logs = logs_array
			results[i] = failure_result
			
			failed_count += 1
			critical_failures += 1
			_stats.failed_effects += 1
			_stats.edge_cases_handled += 1
			
			if not _allow_partial_batch_success:
				break
	
	var total_batch_time = Time.get_ticks_msec() - batch_start_time
	
	# Update batch statistics
	_stats.total_effects_processed += processing_effects.size()
	_stats.batch_count += 1
	_stats.total_processing_time_ms += total_batch_time
	_batch_performance_stats.batches_optimized += 1
	
	# Calculate performance improvements
	var estimated_standard_time = processing_effects.size() * 10  # Rough estimate
	var time_saved = max(0, estimated_standard_time - total_batch_time)
	_batch_performance_stats.processing_time_saved_ms += time_saved
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Optimized batch complete - %d processed, %d failed in %dms (saved ~%dms)" % [
			processed_count, failed_count, total_batch_time, time_saved
		])
	
	batch_completed.emit(results)
	return results

## Standard batch processing for smaller effect sets
func _process_effects_standard(effects: Array[HandlerBase], context: HandlerContext, batch_start_time: int) -> Array[HandlerResult]:
	var results: Array[HandlerResult] = []
	
	# Enhanced input validation with graceful error handling
	var validation_result = _validate_batch_inputs_enhanced(effects, context)
	if not validation_result.valid:
		_safe_log("error", "EffectProcessor: Batch validation failed - %s" % validation_result.error_message)
		_stats.validation_failures += 1
		
		# Attempt recovery if enabled
		if _error_recovery_enabled and validation_result.recoverable:
			var recovery_result = _attempt_batch_recovery(effects, context, validation_result)
			if recovery_result.success:
				_safe_log("warn", "EffectProcessor: Batch validation recovered - %s" % recovery_result.recovery_action)
				_stats.error_recoveries += 1
				error_recovered.emit("batch_validation", recovery_result.recovery_action, {
					"original_error": validation_result.error_message,
					"effect_count": effects.size() if effects else 0
				})
				# Continue with recovered data
				effects = recovery_result.recovered_effects as Array[HandlerBase]
				context = recovery_result.recovered_context
			else:
				# Recovery failed, return empty results but don't crash
				_handle_critical_error("batch_validation_unrecoverable", {
					"error": validation_result.error_message,
					"recovery_attempted": true,
					"recovery_error": recovery_result.error_message
				})
				batch_completed.emit(results)
				return results
		else:
			# No recovery attempted or not enabled
			_handle_critical_error("batch_validation_failed", {
				"error": validation_result.error_message,
				"recovery_enabled": _error_recovery_enabled
			})
			batch_completed.emit(results)
			return results
	
	# Enhanced logging for batch start
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Starting standard batch processing of %d effects from %s" % [effects.size(), context.source_type])
		_log_context_details(context, "batch_start")
	
	# Ensure deterministic processing order if enabled
	var processing_effects = effects
	if _deterministic_mode and _sort_effects_by_id:
		processing_effects = _sort_effects_for_deterministic_processing(effects)
		if DEBUG_ENABLED and processing_effects != effects:
			_safe_log("debug", "EffectProcessor: Effects sorted for deterministic processing")
		if processing_effects != effects:
			_stats.effects_sorted_for_determinism += 1
	
	# Add debug trace entry
	if _debug_trace_enabled:
		_add_debug_trace("batch_start", {
			"effect_count": processing_effects.size(),
			"source_type": context.source_type,
			"deterministic_mode": _deterministic_mode,
			"effects_sorted": processing_effects != effects,
			"timestamp": Time.get_ticks_msec()
		})
	
	var processed_count = 0
	var failed_count = 0
	var batch_processing_time = 0
	var critical_failures = 0
	
	# Process each effect with enhanced error handling
	for i in range(processing_effects.size()):
		var effect = processing_effects[i]
		var effect_start_time = Time.get_ticks_msec()
		
		if DEBUG_ENABLED:
			_safe_log("trace", "EffectProcessor: Processing effect %d/%d: %s" % [i + 1, processing_effects.size(), _safe_get_effect_id(effect)])
		
		# Enhanced null safety check
		if not _null_safety_enabled or _validate_effect_for_processing(effect, i):
			var result = process_single_effect(effect, context)
			results.append(result)
			
			var effect_processing_time = Time.get_ticks_msec() - effect_start_time
			batch_processing_time += effect_processing_time
			
			# Update performance statistics
			_update_effect_performance_stats(effect_processing_time)
			
			# Check for performance warnings
			if effect_processing_time > _performance_thresholds.effect_processing_ms:
				_safe_log("warn", "EffectProcessor: Slow effect processing detected - %s took %dms" % [_safe_get_effect_id(effect), effect_processing_time])
				performance_warning.emit("effect_processing", effect_processing_time, _performance_thresholds.effect_processing_ms)
			
			# Determine if this is a critical failure (for failed effects)
			var is_critical = false
			if not result.success:
				is_critical = _is_critical_failure(result)
			
			if result.success:
				processed_count += 1
				_stats.successful_effects += 1
				effect_executed.emit(effect, result, context)
				
				if DEBUG_ENABLED:
					_safe_log("debug", "EffectProcessor: Effect %d (%s) succeeded in %dms" % [i, _safe_get_effect_id(effect), effect_processing_time])
					_log_effect_result_details(effect, result, effect_processing_time)
			else:
				failed_count += 1
				_stats.failed_effects += 1
				
				if is_critical:
					critical_failures += 1
				
				var reason = _extract_failure_reason(result)
				effect_failed.emit(effect, reason, context)
				
				_safe_log("warn", "EffectProcessor: Effect %d (%s) failed in %dms: %s%s" % [
					i, _safe_get_effect_id(effect), effect_processing_time, reason,
					" [CRITICAL]" if is_critical else ""
				])
				
				# Enhanced failure logging
				if DEBUG_ENABLED:
					_log_effect_failure_details(effect, result, context, effect_processing_time)
				
				# Check if we should abort batch processing due to critical failures
				if not _allow_partial_batch_success and is_critical:
					_safe_log("error", "EffectProcessor: Aborting batch due to critical failure in effect %d" % i)
					_handle_critical_error("batch_aborted_critical_failure", {
						"failed_effect_index": i,
						"effect_id": _safe_get_effect_id(effect),
						"failure_reason": reason
					})
					break
			
			# Add debug trace for each effect
			if _debug_trace_enabled:
				_add_debug_trace("effect_processed", {
					"effect_id": _safe_get_effect_id(effect),
					"success": result.success,
					"processing_time_ms": effect_processing_time,
					"index": i,
					"is_critical": is_critical,
					"timestamp": Time.get_ticks_msec()
				})
		else:
			# Effect failed validation, create a failure result
			var failure_result = _create_validation_failure_result("Effect failed validation at index %d" % i)
			results.append(failure_result)
			failed_count += 1
			critical_failures += 1
			_stats.failed_effects += 1
			_stats.edge_cases_handled += 1
			
			_safe_log("warn", "EffectProcessor: Effect %d failed validation and was skipped" % i)
			
			# Check if we should abort due to validation failures
			if not _allow_partial_batch_success:
				_safe_log("error", "EffectProcessor: Aborting batch due to validation failure in effect %d" % i)
				break
	
	var total_batch_time = Time.get_ticks_msec() - batch_start_time
	
	# Update batch statistics
	_stats.total_effects_processed += processing_effects.size()
	_stats.batch_count += 1
	_stats.total_processing_time_ms += total_batch_time
	
	# Track critical failures
	if critical_failures > 0:
		_stats.critical_errors += critical_failures
		_critical_errors_count += critical_failures
	
	# Calculate average processing time
	if _stats.total_effects_processed > 0:
		_stats.average_effect_time_ms = float(_stats.total_processing_time_ms) / float(_stats.total_effects_processed)
	
	# Check for batch performance warnings
	if total_batch_time > _performance_thresholds.batch_processing_ms:
		_safe_log("warn", "EffectProcessor: Slow batch processing detected - %d effects took %dms" % [processing_effects.size(), total_batch_time])
		performance_warning.emit("batch_processing", total_batch_time, _performance_thresholds.batch_processing_ms)
	
	# Enhanced completion logging
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Standard batch complete - %d processed, %d failed (%d critical) in %dms (avg: %.1fms per effect)" % [
			processed_count, failed_count, critical_failures, total_batch_time, 
			float(batch_processing_time) / float(processing_effects.size()) if processing_effects.size() > 0 else 0.0
		])
		
		# Log performance summary
		_log_batch_performance_summary(processing_effects.size(), total_batch_time, batch_processing_time)
	
	# Check for critical error threshold
	if _critical_errors_count >= _critical_error_threshold:
		_safe_log("error", "EffectProcessor: Critical error threshold reached (%d/%d)" % [_critical_errors_count, _critical_error_threshold])
		critical_error_detected.emit("threshold_exceeded", {
			"current_count": _critical_errors_count,
			"threshold": _critical_error_threshold,
			"batch_critical_failures": critical_failures
		})
	
	# Add processing history entry
	_add_processing_history_entry("batch", {
		"effect_count": processing_effects.size(),
		"processed_count": processed_count,
		"failed_count": failed_count,
		"critical_failures": critical_failures,
		"total_time_ms": total_batch_time,
		"source_type": context.source_type,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Add final debug trace entry
	if _debug_trace_enabled:
		_add_debug_trace("batch_complete", {
			"processed_count": processed_count,
			"failed_count": failed_count,
			"critical_failures": critical_failures,
			"total_time_ms": total_batch_time,
			"timestamp": Time.get_ticks_msec()
		})
	
	batch_completed.emit(results)
	return results

## Process a single effect
func process_single_effect(effect: HandlerBase, context: HandlerContext) -> HandlerResult:
	var effect_start_time = Time.get_ticks_msec()
	var result = HandlerResult.new()
	
	# Enhanced validation with detailed error reporting and recovery
	var validation_result = _validate_single_effect_inputs(effect, context)
	if not validation_result.valid:
		result.success = false
		result.logs.append(validation_result.error_message)
		
		# Attempt recovery if enabled and possible
		if _error_recovery_enabled and validation_result.recoverable:
			var recovery_result = _attempt_effect_recovery(effect, context, validation_result)
			if recovery_result.success:
				_safe_log("warn", "EffectProcessor: Effect validation recovered - %s" % recovery_result.recovery_action)
				_stats.error_recoveries += 1
				error_recovered.emit("effect_validation", recovery_result.recovery_action, {
					"effect_id": _safe_get_effect_id(effect),
					"original_error": validation_result.error_message
				})
				# Continue with recovered data
				effect = recovery_result.recovered_effect
				context = recovery_result.recovered_context
			else:
				# Recovery failed, return failure result
				_safe_log("error", "EffectProcessor: Effect validation failed and recovery unsuccessful - %s" % validation_result.error_message)
				_stats.validation_failures += 1
				_handle_validation_error("effect_validation", validation_result.error_message, {
					"effect_id": _safe_get_effect_id(effect),
					"effect_type": effect.get_class() if effect else "null",
					"context_type": context.source_type if context else "null"
				})
				return result
		else:
			# No recovery attempted
			_safe_log("error", "EffectProcessor: Effect validation failed - %s" % validation_result.error_message)
			_stats.validation_failures += 1
			_handle_validation_error("effect_validation", validation_result.error_message, {
				"effect_id": _safe_get_effect_id(effect),
				"recovery_enabled": _error_recovery_enabled
			})
			return result
	
	# Enhanced debug logging with more context information
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Processing effect %s from %s (target: %s)" % [
			_safe_get_effect_id(effect), 
			context.source_type,
			_get_target_description(context.primary_target)
		])
		
		# Log additional context details for debugging
		if DEBUG_ENABLED:
			_log_detailed_effect_context(effect, context)
	
	# Add debug trace for effect start
	if _debug_trace_enabled:
		_add_debug_trace("effect_start", {
			"effect_id": _safe_get_effect_id(effect),
			"source_type": context.source_type,
			"target": _get_target_description(context.primary_target),
			"timestamp": Time.get_ticks_msec()
		})
	
	# Check if effect can be applied with enhanced error handling
	var can_apply_start_time = Time.get_ticks_msec()
	var can_apply_result: bool = false
	
	# Safely call can_apply with error handling
	if effect.has_method("can_apply"):
		can_apply_result = effect.can_apply(context)
	else:
		_safe_log("error", "EffectProcessor: Effect %s missing can_apply method" % _safe_get_effect_id(effect))
		result.success = false
		result.logs.append("Effect missing can_apply method")
		_stats.critical_errors += 1
		_handle_critical_error("missing_can_apply_method", {
			"effect_id": _safe_get_effect_id(effect),
			"effect_type": effect.get_class()
		})
		return result
	
	var can_apply_time = Time.get_ticks_msec() - can_apply_start_time
	
	if not can_apply_result:
		result.success = false
		result.logs.append("Effect cannot be applied in current context")
		
		if DEBUG_ENABLED:
			_safe_log("debug", "EffectProcessor: Effect %s cannot be applied - conditions not met (check took %dms)" % [_safe_get_effect_id(effect), can_apply_time])
			_log_effect_application_failure(effect, context)
		
		if _debug_trace_enabled:
			_add_debug_trace("effect_cannot_apply", {
				"effect_id": _safe_get_effect_id(effect),
				"check_time_ms": can_apply_time,
				"timestamp": Time.get_ticks_msec()
			})
		
		return result
	
	# Apply the effect with enhanced error handling and recovery
	var apply_start_time = Time.get_ticks_msec()
	var apply_result: HandlerResult = null
	
	# Safely call apply_effect with comprehensive error handling
	if effect.has_method("apply_effect"):
		apply_result = effect.apply_effect(context)
	else:
		_safe_log("error", "EffectProcessor: Effect %s missing apply_effect method" % _safe_get_effect_id(effect))
		result.success = false
		result.logs.append("Effect missing apply_effect method")
		_stats.critical_errors += 1
		_handle_critical_error("missing_apply_effect_method", {
			"effect_id": _safe_get_effect_id(effect),
			"effect_type": effect.get_class()
		})
		return result
	
	var apply_time = Time.get_ticks_msec() - apply_start_time
	
	# Enhanced result validation and error handling
	if not apply_result:
		result.success = false
		result.logs.append("Effect returned null result")
		_safe_log("error", "EffectProcessor: Effect %s returned null result (apply took %dms)" % [_safe_get_effect_id(effect), apply_time])
		
		# Attempt to create a default result if malformed data recovery is enabled
		if _malformed_data_recovery:
			result = _create_default_effect_result("Null result recovered with default values")
			_stats.malformed_data_encountered += 1
			_safe_log("warn", "EffectProcessor: Created default result for null return from effect %s" % _safe_get_effect_id(effect))
		
		if _debug_trace_enabled:
			_add_debug_trace("effect_null_result", {
				"effect_id": _safe_get_effect_id(effect),
				"apply_time_ms": apply_time,
				"recovery_attempted": _malformed_data_recovery,
				"timestamp": Time.get_ticks_msec()
			})
	elif not _validate_effect_result(apply_result):
		# Result is malformed, attempt recovery
		if _malformed_data_recovery:
			var recovered_result = _recover_malformed_result(apply_result, effect)
			if recovered_result:
				result = recovered_result
				_stats.malformed_data_encountered += 1
				_safe_log("warn", "EffectProcessor: Recovered malformed result from effect %s" % _safe_get_effect_id(effect))
			else:
				result.success = false
				result.logs.append("Malformed result could not be recovered")
				_safe_log("error", "EffectProcessor: Effect %s returned malformed result that could not be recovered" % _safe_get_effect_id(effect))
		else:
			result.success = false
			result.logs.append("Effect returned malformed result")
			_safe_log("error", "EffectProcessor: Effect %s returned malformed result" % _safe_get_effect_id(effect))
	elif not apply_result.success:
		result = apply_result
		result.logs.append("Effect application failed")
		_safe_log("warn", "EffectProcessor: Effect %s application failed (apply took %dms)" % [_safe_get_effect_id(effect), apply_time])
		
		if DEBUG_ENABLED:
			_log_effect_application_error(effect, result, apply_time)
		
		if _debug_trace_enabled:
			_add_debug_trace("effect_application_failed", {
				"effect_id": _safe_get_effect_id(effect),
				"apply_time_ms": apply_time,
				"error_logs": result.logs,
				"timestamp": Time.get_ticks_msec()
			})
	else:
		# Success case - use the returned result
		result = apply_result
		
		# Success case - log detailed results if trace level enabled
		if DEBUG_ENABLED and GLog.min_log_level <= GLog.Level.TRACE:
			_log_successful_effect_details(effect, result, apply_time)
		
		if _debug_trace_enabled:
			_add_debug_trace("effect_success", {
				"effect_id": _safe_get_effect_id(effect),
				"apply_time_ms": apply_time,
				"values_applied": result.values_applied,
				"timestamp": Time.get_ticks_msec()
			})
	
	var total_effect_time = Time.get_ticks_msec() - effect_start_time
	
	# Log performance information
	if DEBUG_ENABLED and total_effect_time > _performance_thresholds.effect_processing_ms / 2:
		_safe_log("debug", "EffectProcessor: Effect %s processing breakdown - can_apply: %dms, apply: %dms, total: %dms" % [
			_safe_get_effect_id(effect), can_apply_time, apply_time, total_effect_time
		])
	
	return result

## Create context for card effects with enhanced caching and performance monitoring
func create_context_for_card(card_instance: CardInstance, duel_manager: DuelManager) -> HandlerContext:
	var context_start_time = Time.get_ticks_msec()
	
	if DEBUG_ENABLED:
		_safe_log("trace", "EffectProcessor: Creating card context for %s" % (card_instance.card_data.card_name if card_instance and card_instance.card_data else "unknown"))
	
	if not is_instance_valid(card_instance):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid card_instance")
		_stats.validation_failures += 1
		return null
	
	if not is_instance_valid(duel_manager):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid duel_manager")
		_stats.validation_failures += 1
		return null
	
	# Try to get context from cache first
	var cache_key = _generate_card_context_cache_key(card_instance, duel_manager)
	var cached_context = _get_cached_context(cache_key)
	if cached_context:
		_context_performance_stats.cache_hits += 1
		_context_performance_stats.contexts_reused += 1
		
		# Update context with current state (some data may have changed)
		_update_cached_card_context(cached_context, card_instance, duel_manager)
		
		var total_time = Time.get_ticks_msec() - context_start_time
		_update_context_performance_stats(total_time, 0)  # No curio lookup time for cached contexts
		
		if DEBUG_ENABLED:
			_safe_log("trace", "EffectProcessor: Reused cached card context in %dms" % total_time)
		
		return cached_context
	
	_context_performance_stats.cache_misses += 1
	
	# Get context from pool or create new one
	var context = _get_pooled_context()
	if context != null:
		_context_performance_stats.contexts_pooled += 1
	else:
		context = HandlerContext.new()
	
	_context_performance_stats.contexts_created += 1
	
	# Set source information
	context.source_type = "card"
	context.source_object = card_instance.card_data if card_instance else null
	
	# Set state references
	context.duel_manager = duel_manager
	if duel_manager and duel_manager.duel_state:
		context.player_data = duel_manager.duel_state.player_data
		context.enemy_data = duel_manager.duel_state.enemy_data
	else:
		_safe_log("warn", "EffectProcessor: DuelManager has no duel_state when creating card context")
	
	# Set trigger information
	context.trigger_event = "card_played"
	context.trigger_data = {
		"card_instance": card_instance,
		"duel_state": duel_manager.duel_state if duel_manager else null
	}
	
	# Set targeting based on card ownership and type
	if card_instance and card_instance.card_data:
		var is_player_owned = card_instance.owner == CardInstance.Owner.PLAYER
		var card_type = card_instance.card_data.card_type if card_instance.card_data else ""
		
		# Attack cards target the opponent, other cards typically target self
		if card_type == "Attack":
			context.primary_target = context.enemy_data if is_player_owned else context.player_data
		else:
			context.primary_target = context.player_data if is_player_owned else context.enemy_data
		
		if DEBUG_ENABLED:
			_safe_log("debug", "EffectProcessor: Created card context - owner: %s, type: %s, target: %s" % [
				"player" if is_player_owned else "enemy",
				card_type,
				_get_target_description(context.primary_target)
			])
	
	# Add curio modifications for player cards with timing
	var curio_start_time = Time.get_ticks_msec()
	if CurioManager and context.source_object and card_instance:
		var is_player_owned = card_instance.owner == CardInstance.Owner.PLAYER
		if CurioManager.has_method("calculate_card_modifications"):
			context.curio_modifications = CurioManager.calculate_card_modifications(context.source_object, is_player_owned)
			
			if DEBUG_ENABLED and not context.curio_modifications.is_empty():
				_safe_log("trace", "EffectProcessor: Applied %d curio modifications to card context" % context.curio_modifications.size())
		else:
			_safe_log("warn", "EffectProcessor: CurioManager missing calculate_card_modifications method")
	
	var curio_time = Time.get_ticks_msec() - curio_start_time
	var total_context_time = Time.get_ticks_msec() - context_start_time
	
	# Update performance statistics
	_update_context_performance_stats(total_context_time, curio_time)
	
	# Check for performance warnings
	if total_context_time > _performance_thresholds.context_creation_ms:
		_safe_log("warn", "EffectProcessor: Slow card context creation - took %dms (curio lookup: %dms)" % [total_context_time, curio_time])
		performance_warning.emit("context_creation", total_context_time, _performance_thresholds.context_creation_ms)
	
	# Cache the context for future reuse
	_cache_context(cache_key, context)
	
	# Add debug trace
	if _debug_trace_enabled:
		_add_debug_trace("card_context_created", {
			"card_name": card_instance.card_data.card_name if card_instance.card_data else "unknown",
			"creation_time_ms": total_context_time,
			"curio_modifications": context.curio_modifications.size(),
			"cached": false,
			"pooled": _context_performance_stats.contexts_pooled > 0,
			"timestamp": Time.get_ticks_msec()
		})
	
	if DEBUG_ENABLED and GLog.min_log_level <= GLog.Level.TRACE:
		_safe_log("trace", "EffectProcessor: Card context creation complete in %dms" % total_context_time)
	
	return context

## Create context for encounter effects
func create_context_for_encounter(encounter: EncounterData, player_data: PlayerData) -> HandlerContext:
	if not is_instance_valid(encounter):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid encounter")
		return null
	
	if not is_instance_valid(player_data):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid player_data")
		return null
	
	var context = HandlerContext.new()
	
	# Set source information
	context.source_type = "encounter"
	context.source_object = encounter
	
	# Set state references
	context.player_data = player_data
	context.game_manager = GameManager if GameManager else null
	
	# Set trigger information
	context.trigger_event = "encounter_choice"
	context.trigger_data = {
		"encounter": encounter,
		"player_data": player_data
	}
	
	# Encounters typically target the player
	context.primary_target = player_data
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Created encounter context for %s" % _get_target_description(encounter))
	
	return context

## Create context for curio effects
func create_context_for_curio(curio: CurioData, trigger_event: String, game_state: Resource) -> HandlerContext:
	if not is_instance_valid(curio):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid curio")
		return null
	
	if trigger_event.is_empty():
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - empty trigger_event")
		return null
	
	if not is_instance_valid(game_state):
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Cannot create context - invalid game_state")
		return null
	
	var context = HandlerContext.new()
	
	# Set source information
	context.source_type = "curio"
	context.source_object = curio
	
	# Set state references based on game state type
	if game_state is DuelState:
		var duel_state = game_state as DuelState
		context.duel_manager = null  # Will be set by caller if available
		context.player_data = duel_state.player_data
		context.enemy_data = duel_state.enemy_data
	elif game_state is PlayerData:
		context.player_data = game_state as PlayerData
	else:
		_safe_log("warn", "EffectProcessor: Unknown game_state type: %s" % game_state.get_class())
	
	context.game_manager = GameManager if GameManager else null
	
	# Set trigger information
	context.trigger_event = trigger_event
	context.trigger_data = {
		"curio": curio,
		"game_state": game_state
	}
	
	# Curios typically affect the player
	context.primary_target = context.player_data
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Created curio context for %s on %s" % [
			_get_target_description(curio),
			trigger_event
		])
	
	return context

## Validate batch processing inputs
func _validate_batch_inputs(effects: Array[HandlerBase], context: HandlerContext) -> bool:
	if effects.is_empty():
		_safe_log("warn", "EffectProcessor: Empty effects array provided")
		return false
	
	if not is_instance_valid(context):
		_safe_log("error", "EffectProcessor: Invalid context provided")
		return false
	
	if context.source_type.is_empty():
		_safe_log("error", "EffectProcessor: Context missing source_type")
		return false
	
	# Validate each effect in the array
	for i in range(effects.size()):
		if not is_instance_valid(effects[i]):
			_safe_log("error", "EffectProcessor: Invalid effect at index %d" % i)
			return false
		
		if not effects[i] is HandlerBase:
			_safe_log("error", "EffectProcessor: Non-HandlerBase at index %d (type: %s)" % [i, effects[i].get_class()])
			return false
		
		if effects[i].effect_id.is_empty():
			_safe_log("warn", "EffectProcessor: Effect at index %d has empty effect_id" % i)
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Batch validation passed for %d effects" % effects.size())
	
	return true

## Enable or disable context caching for performance optimization
func set_context_caching(enabled: bool) -> void:
	_cache_enabled = enabled
	if not enabled:
		_context_cache.clear()

## Clear the context cache
func clear_context_cache() -> void:
	_context_cache.clear()

## Configure context optimization settings
func configure_context_optimization(config: Dictionary) -> void:
	"""Configure context optimization settings.
	
	Args:
		config: Dictionary with optimization settings:
		- cache_enabled: bool - Enable/disable context caching
		- cache_max_size: int - Maximum number of cached contexts
		- cache_ttl_ms: int - Time-to-live for cached contexts in milliseconds
		- object_pool_enabled: bool - Enable/disable context object pooling
		- max_pool_size: int - Maximum size for context object pool
	"""
	if config.has("cache_enabled"):
		_cache_enabled = config.cache_enabled
		if not _cache_enabled:
			_context_cache.clear()
	
	if config.has("cache_max_size"):
		_context_cache_max_size = max(10, config.cache_max_size)
		_trim_context_cache()
	
	if config.has("cache_ttl_ms"):
		_context_cache_ttl_ms = max(1000, config.cache_ttl_ms)  # Minimum 1 second TTL
	
	if config.has("object_pool_enabled"):
		_object_pool_enabled = config.object_pool_enabled
		if not _object_pool_enabled:
			_context_pool.clear()
	
	if config.has("max_pool_size"):
		_max_pool_size = max(10, config.max_pool_size)
		while _context_pool.size() > _max_pool_size:
			_context_pool.pop_back()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Context optimization configured: %s" % str(config))

## Get current context optimization configuration
func get_context_optimization_config() -> Dictionary:
	"""Get current context optimization configuration."""
	return {
		"cache_enabled": _cache_enabled,
		"cache_max_size": _context_cache_max_size,
		"cache_ttl_ms": _context_cache_ttl_ms,
		"object_pool_enabled": _object_pool_enabled,
		"max_pool_size": _max_pool_size,
		"current_cache_size": _context_cache.size(),
		"current_pool_size": _context_pool.size()
	}

## Get context performance statistics
func get_context_performance_stats() -> Dictionary:
	"""Get performance statistics for context creation and caching."""
	var stats = _context_performance_stats.duplicate()
	
	# Add calculated metrics
	if stats.contexts_created > 0:
		stats.pool_reuse_rate = float(stats.contexts_pooled) / float(stats.contexts_created)
		stats.average_creation_time_ms = float(stats.total_creation_time_ms) / float(stats.contexts_created)
	else:
		stats.pool_reuse_rate = 0.0
		stats.average_creation_time_ms = 0.0
	
	if (stats.cache_hits + stats.cache_misses) > 0:
		stats.cache_hit_rate = float(stats.cache_hits) / float(stats.cache_hits + stats.cache_misses)
	else:
		stats.cache_hit_rate = 0.0
	
	# Add global HandlerContext statistics
	stats.global_stats = HandlerContext.get_global_performance_stats()
	
	return stats

## Reset context performance statistics
func reset_context_performance_stats() -> void:
	"""Reset context performance statistics."""
	_context_performance_stats = {
		"contexts_created": 0,
		"contexts_reused": 0,
		"cache_hits": 0,
		"cache_misses": 0,
		"cache_evictions": 0,
		"total_creation_time_ms": 0,
		"total_curio_lookup_time_ms": 0,
		"average_creation_time_ms": 0.0,
		"peak_creation_time_ms": 0,
		"contexts_pooled": 0,
		"pool_reuse_rate": 0.0
	}
	
	# Also reset global HandlerContext statistics
	HandlerContext.reset_global_performance_stats()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Context performance statistics reset")

## Generate a cache key for card contexts
func _generate_card_context_cache_key(card_instance: CardInstance, duel_manager: DuelManager) -> String:
	"""Generate a cache key for card contexts based on card and game state."""
	if not card_instance or not card_instance.card_data or not duel_manager:
		return ""
	
	# Create key based on card name and relevant game state
	var card_name = card_instance.card_data.card_name if card_instance.card_data.card_name else "unknown"
	var card_owner = "player" if card_instance.owner == CardInstance.Owner.PLAYER else "enemy"
	
	# Include relevant state that affects context
	var state_hash = ""
	if duel_manager.duel_state:
		var duel_state = duel_manager.duel_state
		state_hash = "%d_%d_%d" % [
			duel_state.turn_number if "turn_number" in duel_state else 0,
			duel_state.player_energy if "player_energy" in duel_state else 0,
			duel_state.cards_played_this_turn if "cards_played_this_turn" in duel_state else 0
		]
	
	return "card_%s_%s_%s" % [card_name, card_owner, state_hash]

## Get a cached context if available and not expired
func _get_cached_context(cache_key: String) -> HandlerContext:
	"""Get a cached context if available and not expired."""
	if not _cache_enabled or cache_key.is_empty():
		return null
	
	if not _context_cache.has(cache_key):
		return null
	
	var cache_entry = _context_cache[cache_key]
	var current_time = Time.get_ticks_msec()
	
	# Check if cache entry has expired
	if current_time - cache_entry.timestamp > _context_cache_ttl_ms:
		_context_cache.erase(cache_key)
		_context_performance_stats.cache_evictions += 1
		return null
	
	# Return a copy of the cached context to avoid reference issues
	var cached_context = cache_entry.context
	if cached_context and is_instance_valid(cached_context):
		return cached_context
	else:
		# Invalid cached context, remove it
		_context_cache.erase(cache_key)
		return null

## Cache a context for future reuse
func _cache_context(cache_key: String, context: HandlerContext) -> void:
	"""Cache a context for future reuse."""
	if not _cache_enabled or cache_key.is_empty() or not context:
		return
	
	# Trim cache if it's getting too large
	_trim_context_cache()
	
	# Store context with timestamp
	_context_cache[cache_key] = {
		"context": context,
		"timestamp": Time.get_ticks_msec()
	}

## Trim context cache to stay within size limits
func _trim_context_cache() -> void:
	"""Remove oldest entries from context cache to stay within size limits."""
	while _context_cache.size() >= _context_cache_max_size:
		var oldest_key = ""
		var oldest_timestamp = Time.get_ticks_msec()
		
		# Find oldest entry
		for key in _context_cache.keys():
			var entry = _context_cache[key]
			if entry.timestamp < oldest_timestamp:
				oldest_timestamp = entry.timestamp
				oldest_key = key
		
		if not oldest_key.is_empty():
			_context_cache.erase(oldest_key)
			_context_performance_stats.cache_evictions += 1

## Update a cached card context with current state
func _update_cached_card_context(context: HandlerContext, card_instance: CardInstance, duel_manager: DuelManager) -> void:
	"""Update a cached card context with current state that may have changed."""
	if not context or not card_instance or not duel_manager:
		return
	
	# Update state references that may have changed
	context.duel_manager = duel_manager
	if duel_manager.duel_state:
		context.player_data = duel_manager.duel_state.player_data
		context.enemy_data = duel_manager.duel_state.enemy_data
	
	# Update trigger data with current state
	context.trigger_data["card_instance"] = card_instance
	context.trigger_data["duel_state"] = duel_manager.duel_state if duel_manager else null
	
	# Invalidate any cached calculations since state may have changed
	context.invalidate_cache()

## Update context performance statistics
func _update_context_performance_stats(total_time_ms: int, curio_time_ms: int) -> void:
	"""Update context performance statistics with timing information."""
	_context_performance_stats.total_creation_time_ms += total_time_ms
	_context_performance_stats.total_curio_lookup_time_ms += curio_time_ms
	
	if total_time_ms > _context_performance_stats.peak_creation_time_ms:
		_context_performance_stats.peak_creation_time_ms = total_time_ms
	
	if _context_performance_stats.contexts_created > 0:
		_context_performance_stats.average_creation_time_ms = float(_context_performance_stats.total_creation_time_ms) / float(_context_performance_stats.contexts_created)

## Benchmark context creation performance
func benchmark_context_creation(iterations: int = 100) -> Dictionary:
	"""Benchmark context creation performance with different optimization settings.
	
	Args:
		iterations: Number of iterations per test
		
	Returns:
		Dictionary with benchmark results
	"""
	var benchmark_results = {
		"test_timestamp": Time.get_datetime_string_from_system(),
		"iterations": iterations,
		"results": {}
	}
	
	# Store original settings
	var original_cache_enabled = _cache_enabled
	var original_pool_enabled = _object_pool_enabled
	
	# Create test data - use a simple mock instead of preloading
	var test_card_data = CardData.new() if CardData else null
	if test_card_data:
		test_card_data.card_name = "Benchmark Test Card"
		test_card_data.card_type = "Attack"
	var test_card_instance = CardInstance.new()
	if test_card_data:
		test_card_instance.card_data = test_card_data
		test_card_instance.owner = CardInstance.Owner.PLAYER
	else:
		# Skip benchmark if we can't create test data
		benchmark_results.error = "Could not create test card data"
		return benchmark_results
	
	var test_duel_manager = DuelManager.new()  # This might need to be mocked
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Starting context creation benchmark with %d iterations" % iterations)
	
	# Test scenarios
	var test_scenarios = [
		{"name": "no_optimization", "cache": false, "pool": false},
		{"name": "cache_only", "cache": true, "pool": false},
		{"name": "pool_only", "cache": false, "pool": true},
		{"name": "full_optimization", "cache": true, "pool": true}
	]
	
	for scenario in test_scenarios:
		_cache_enabled = scenario.cache
		_object_pool_enabled = scenario.pool
		
		# Clear caches and pools for clean test
		_context_cache.clear()
		_context_pool.clear()
		
		var times = []
		var total_start_time = Time.get_ticks_msec()
		
		for i in range(iterations):
			var start_time = Time.get_ticks_msec()
			var context = create_context_for_card(test_card_instance, test_duel_manager)
			var end_time = Time.get_ticks_msec()
			
			if context:
				times.append(end_time - start_time)
				# Return context to pool if pooling is enabled
				if _object_pool_enabled:
					_return_pooled_context(context)
		
		var total_time = Time.get_ticks_msec() - total_start_time
		
		# Calculate statistics
		var avg_time = 0.0
		var min_time = 999999
		var max_time = 0
		
		if not times.is_empty():
			var sum_time = 0
			for time in times:
				sum_time += time
				if time < min_time:
					min_time = time
				if time > max_time:
					max_time = time
			avg_time = float(sum_time) / float(times.size())
		
		benchmark_results.results[scenario.name] = {
			"cache_enabled": scenario.cache,
			"pool_enabled": scenario.pool,
			"total_time_ms": total_time,
			"average_time_ms": avg_time,
			"min_time_ms": min_time,
			"max_time_ms": max_time,
			"successful_creations": times.size(),
			"cache_size": _context_cache.size(),
			"pool_size": _context_pool.size()
		}
	
	# Restore original settings
	_cache_enabled = original_cache_enabled
	_object_pool_enabled = original_pool_enabled
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Context creation benchmark complete")
		for scenario_name in benchmark_results.results.keys():
			var result = benchmark_results.results[scenario_name]
			_safe_log("info", "  %s: %.2fms avg (min: %dms, max: %dms)" % [
				scenario_name, result.average_time_ms, result.min_time_ms, result.max_time_ms
			])
	
	return benchmark_results

## Get processing diagnostics for debugging
func get_processing_diagnostics() -> Dictionary:
	var diagnostics = {
		"cache_enabled": _cache_enabled,
		"cached_contexts": _context_cache.size(),
		"debug_enabled": DEBUG_ENABLED,
		"trace_enabled": _debug_trace_enabled,
		"statistics": _stats.duplicate(),
		"performance_thresholds": _performance_thresholds.duplicate(),
		"trace_buffer_size": _debug_trace_buffer.size(),
		"history_entries": _processing_history.size(),
		"context_performance": get_context_performance_stats(),
		"batch_performance": get_batch_performance_stats()
	}
	
	# Add calculated metrics
	if _stats.total_effects_processed > 0:
		diagnostics["success_rate"] = float(_stats.successful_effects) / float(_stats.total_effects_processed)
		diagnostics["failure_rate"] = float(_stats.failed_effects) / float(_stats.total_effects_processed)
	else:
		diagnostics["success_rate"] = 0.0
		diagnostics["failure_rate"] = 0.0
	
	if _stats.batch_count > 0:
		diagnostics["average_batch_time_ms"] = float(_stats.total_processing_time_ms) / float(_stats.batch_count)
		diagnostics["average_effects_per_batch"] = float(_stats.total_effects_processed) / float(_stats.batch_count)
	else:
		diagnostics["average_batch_time_ms"] = 0.0
		diagnostics["average_effects_per_batch"] = 0.0
	
	return diagnostics

## Reset processing statistics
func reset_statistics() -> void:
	_stats = {
		"total_effects_processed": 0,
		"successful_effects": 0,
		"failed_effects": 0,
		"batch_count": 0,
		"total_processing_time_ms": 0,
		"average_effect_time_ms": 0.0,
		"slowest_effect_time_ms": 0,
		"fastest_effect_time_ms": 999999,
		"cache_hits": 0,
		"cache_misses": 0,
		"validation_failures": 0,
		"context_creation_time_ms": 0,
		"error_recoveries": 0,
		"critical_errors": 0,
		"malformed_data_encountered": 0,
		"null_safety_activations": 0,
		"edge_cases_handled": 0,
		"deterministic_validations_run": 0,
		"deterministic_validations_passed": 0,
		"effects_sorted_for_determinism": 0,
		"batch_optimizations_used": 0,
		"object_allocations_saved": 0,
		"validation_cache_hits": 0
	}
	
	# Also reset batch performance stats
	reset_batch_performance_stats()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Statistics reset")

## Enable or disable debug tracing
func set_debug_trace_enabled(enabled: bool) -> void:
	_debug_trace_enabled = enabled
	if not enabled:
		_debug_trace_buffer.clear()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Debug tracing %s" % ("enabled" if enabled else "disabled"))

## Get debug trace buffer for analysis
func get_debug_trace() -> Array[Dictionary]:
	return _debug_trace_buffer.duplicate()

## Clear debug trace buffer
func clear_debug_trace() -> void:
	_debug_trace_buffer.clear()
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Debug trace buffer cleared")

## Get processing history for debugging
func get_processing_history() -> Array[Dictionary]:
	return _processing_history.duplicate()

## Clear processing history
func clear_processing_history() -> void:
	_processing_history.clear()
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Processing history cleared")

## Set performance monitoring thresholds
func set_performance_thresholds(thresholds: Dictionary) -> void:
	for key in thresholds.keys():
		if _performance_thresholds.has(key):
			_performance_thresholds[key] = thresholds[key]
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Performance thresholds updated: %s" % _performance_thresholds)

## Generate comprehensive debug report
func generate_debug_report() -> Dictionary:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"diagnostics": get_processing_diagnostics(),
		"recent_trace": _debug_trace_buffer.slice(-10) if _debug_trace_buffer.size() > 10 else _debug_trace_buffer.duplicate(),
		"recent_history": _processing_history.slice(-5) if _processing_history.size() > 5 else _processing_history.duplicate(),
		"performance_analysis": _generate_performance_analysis()
	}
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Debug report generated with %d trace entries and %d history entries" % [
			report.recent_trace.size(), report.recent_history.size()
		])
	
	return report

## Log detailed context information for debugging
func _log_context_details(context: HandlerContext, operation: String) -> void:
	if not DEBUG_ENABLED or GLog.min_log_level > GLog.Level.TRACE:
		return
	
	_safe_log("trace", "EffectProcessor: Context details for %s:" % operation)
	_safe_log("trace", "  - Source: %s (%s)" % [context.source_type, _get_target_description(context.source_object)])
	_safe_log("trace", "  - Target: %s" % _get_target_description(context.primary_target))
	_safe_log("trace", "  - Trigger: %s" % context.trigger_event)
	
	if context.curio_modifications and not context.curio_modifications.is_empty():
		_safe_log("trace", "  - Curio modifications: %d active" % context.curio_modifications.size())

## Log detailed effect context for debugging
func _log_detailed_effect_context(effect: HandlerBase, context: HandlerContext) -> void:
	_safe_log("trace", "EffectProcessor: Detailed effect context:")
	_safe_log("trace", "  - Effect ID: %s" % effect.effect_id)
	_safe_log("trace", "  - Effect Type: %s" % effect.get_class())
	
	if effect.has_method("get_description"):
		_safe_log("trace", "  - Description: %s" % effect.get_description())
	
	if context.trigger_data:
		_safe_log("trace", "  - Trigger data keys: %s" % context.trigger_data.keys())

## Log effect result details for successful effects
func _log_effect_result_details(effect: HandlerBase, result: HandlerResult, _processing_time_ms: int) -> void:
	if not result.values_applied.is_empty():
		_safe_log("debug", "EffectProcessor: Effect %s applied values: %s" % [effect.effect_id, result.values_applied])
	
	if not result.logs.is_empty():
		_safe_log("debug", "EffectProcessor: Effect %s logs: %s" % [effect.effect_id, result.logs])

## Log effect failure details for debugging
func _log_effect_failure_details(effect: HandlerBase, result: HandlerResult, context: HandlerContext, processing_time_ms: int) -> void:
	_safe_log("warn", "EffectProcessor: Effect failure analysis for %s:" % effect.effect_id)
	_safe_log("warn", "  - Processing time: %dms" % processing_time_ms)
	_safe_log("warn", "  - Context source: %s" % context.source_type)
	_safe_log("warn", "  - Target: %s" % _get_target_description(context.primary_target))
	
	if not result.logs.is_empty():
		_safe_log("warn", "  - Error logs: %s" % result.logs)

## Log effect application failure details
func _log_effect_application_failure(effect: HandlerBase, context: HandlerContext) -> void:
	_safe_log("debug", "EffectProcessor: Effect %s cannot be applied:" % effect.effect_id)
	_safe_log("debug", "  - Source: %s" % context.source_type)
	_safe_log("debug", "  - Target: %s" % _get_target_description(context.primary_target))
	_safe_log("debug", "  - Trigger: %s" % context.trigger_event)

## Log effect application error details
func _log_effect_application_error(effect: HandlerBase, result: HandlerResult, apply_time_ms: int) -> void:
	_safe_log("warn", "EffectProcessor: Effect %s application error (took %dms):" % [effect.effect_id, apply_time_ms])
	
	if not result.logs.is_empty():
		for log_entry in result.logs:
			_safe_log("warn", "  - %s" % log_entry)

## Log successful effect details for trace level
func _log_successful_effect_details(effect: HandlerBase, result: HandlerResult, apply_time_ms: int) -> void:
	_safe_log("trace", "EffectProcessor: Effect %s success details (took %dms):" % [effect.effect_id, apply_time_ms])
	
	if not result.values_applied.is_empty():
		for key in result.values_applied.keys():
			_safe_log("trace", "  - %s: %s" % [key, result.values_applied[key]])

## Log batch performance summary
func _log_batch_performance_summary(effect_count: int, total_time_ms: int, processing_time_ms: int) -> void:
	var overhead_time = total_time_ms - processing_time_ms
	var overhead_percentage = (float(overhead_time) / float(total_time_ms)) * 100.0 if total_time_ms > 0 else 0.0
	
	_safe_log("debug", "EffectProcessor: Batch performance summary:")
	_safe_log("debug", "  - Effects: %d" % effect_count)
	_safe_log("debug", "  - Total time: %dms" % total_time_ms)
	_safe_log("debug", "  - Processing time: %dms" % processing_time_ms)
	_safe_log("debug", "  - Overhead: %dms (%.1f%%)" % [overhead_time, overhead_percentage])
	_safe_log("debug", "  - Avg per effect: %.1fms" % (float(processing_time_ms) / float(effect_count) if effect_count > 0 else 0.0))

## Add entry to debug trace buffer
func _add_debug_trace(operation: String, data: Dictionary) -> void:
	if not _debug_trace_enabled:
		return
	
	var trace_entry = {
		"operation": operation,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	
	_debug_trace_buffer.append(trace_entry)
	
	# Limit buffer size
	if _debug_trace_buffer.size() > _max_trace_entries:
		_debug_trace_buffer.pop_front()
	
	# Emit signal for real-time debugging
	debug_trace_updated.emit(trace_entry)

## Add entry to processing history
func _add_processing_history_entry(operation_type: String, data: Dictionary) -> void:
	var history_entry = {
		"operation_type": operation_type,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	
	_processing_history.append(history_entry)
	
	# Limit history size
	if _processing_history.size() > _max_history_entries:
		_processing_history.pop_front()

## Update effect performance statistics
func _update_effect_performance_stats(processing_time_ms: int) -> void:
	_stats.total_processing_time_ms += processing_time_ms
	
	if processing_time_ms > _stats.slowest_effect_time_ms:
		_stats.slowest_effect_time_ms = processing_time_ms
	
	if processing_time_ms < _stats.fastest_effect_time_ms:
		_stats.fastest_effect_time_ms = processing_time_ms
	
	# Recalculate average
	if _stats.total_effects_processed > 0:
		_stats.average_effect_time_ms = float(_stats.total_processing_time_ms) / float(_stats.total_effects_processed)

## Generate performance analysis for debug reports
func _generate_performance_analysis() -> Dictionary:
	var analysis = {
		"performance_status": "good",
		"bottlenecks": [],
		"recommendations": [],
		"error_analysis": {}
	}
	
	# Analyze average processing time
	if _stats.average_effect_time_ms > _performance_thresholds.effect_processing_ms:
		analysis.performance_status = "poor"
		analysis.bottlenecks.append("High average effect processing time: %.1fms" % _stats.average_effect_time_ms)
		analysis.recommendations.append("Consider optimizing effect implementations or reducing effect complexity")
	elif _stats.average_effect_time_ms > _performance_thresholds.effect_processing_ms * 0.7:
		analysis.performance_status = "fair"
		analysis.bottlenecks.append("Moderate average effect processing time: %.1fms" % _stats.average_effect_time_ms)
	
	# Analyze failure rate
	var failure_rate = float(_stats.failed_effects) / float(_stats.total_effects_processed) if _stats.total_effects_processed > 0 else 0.0
	if failure_rate > 0.1:  # More than 10% failure rate
		analysis.performance_status = "poor"
		analysis.bottlenecks.append("High effect failure rate: %.1f%%" % (failure_rate * 100.0))
		analysis.recommendations.append("Review effect validation logic and context creation")
	elif failure_rate > 0.05:  # More than 5% failure rate
		if analysis.performance_status == "good":
			analysis.performance_status = "fair"
		analysis.bottlenecks.append("Moderate effect failure rate: %.1f%%" % (failure_rate * 100.0))
	
	# Analyze context creation performance
	var avg_context_time = float(_stats.context_creation_time_ms) / float(_stats.batch_count) if _stats.batch_count > 0 else 0.0
	if avg_context_time > _performance_thresholds.context_creation_ms * 2:
		analysis.bottlenecks.append("Slow context creation: %.1fms average" % avg_context_time)
		analysis.recommendations.append("Consider caching context objects or optimizing curio lookups")
	
	# Analyze error handling metrics
	analysis.error_analysis = {
		"critical_error_rate": float(_stats.critical_errors) / float(_stats.total_effects_processed) if _stats.total_effects_processed > 0 else 0.0,
		"recovery_success_rate": float(_stats.error_recoveries) / float(_stats.validation_failures) if _stats.validation_failures > 0 else 0.0,
		"malformed_data_rate": float(_stats.malformed_data_encountered) / float(_stats.total_effects_processed) if _stats.total_effects_processed > 0 else 0.0,
		"null_safety_activation_rate": float(_stats.null_safety_activations) / float(_stats.total_effects_processed) if _stats.total_effects_processed > 0 else 0.0
	}
	
	# Add error-based recommendations
	if analysis.error_analysis.critical_error_rate > 0.01:  # More than 1% critical errors
		analysis.performance_status = "poor"
		analysis.bottlenecks.append("High critical error rate: %.2f%%" % (analysis.error_analysis.critical_error_rate * 100.0))
		analysis.recommendations.append("Investigate and fix sources of critical errors in effect implementations")
	
	if analysis.error_analysis.malformed_data_rate > 0.05:  # More than 5% malformed data
		if analysis.performance_status == "good":
			analysis.performance_status = "fair"
		analysis.bottlenecks.append("High malformed data rate: %.2f%%" % (analysis.error_analysis.malformed_data_rate * 100.0))
		analysis.recommendations.append("Review effect data validation and serialization processes")
	
	if analysis.error_analysis.null_safety_activation_rate > 0.02:  # More than 2% null safety activations
		analysis.bottlenecks.append("Frequent null safety activations: %.2f%%" % (analysis.error_analysis.null_safety_activation_rate * 100.0))
		analysis.recommendations.append("Improve effect data integrity and validation at creation time")
	
	return analysis

## Get a human-readable description of a target for logging
func _get_target_description(target: Resource) -> String:
	if not target:
		return "none"
	
	if target.has_method("get_name"):
		return target.get_name()
	elif target.has_method("get_character_name"):
		return target.get_character_name()
	elif "name" in target:
		return target.name
	else:
		return target.get_class()

## Enhanced validation for batch inputs with detailed error reporting
func _validate_batch_inputs_enhanced(effects: Array[HandlerBase], context: HandlerContext) -> Dictionary:
	var result = {
		"valid": false,
		"error_message": "",
		"recoverable": false,
		"error_type": ""
	}
	
	# Check for null or empty effects array
	if not effects:
		result.error_message = "Effects array is null"
		result.error_type = "null_effects_array"
		result.recoverable = true  # Can create empty array
		return result
	
	if effects.is_empty():
		result.error_message = "Empty effects array provided"
		result.error_type = "empty_effects_array"
		result.recoverable = false  # Empty is valid, just warn
		result.valid = true
		return result
	
	# Check context validity
	if not is_instance_valid(context):
		result.error_message = "Invalid context provided"
		result.error_type = "invalid_context"
		result.recoverable = false  # Cannot recover from null context
		return result
	
	if context.source_type.is_empty():
		result.error_message = "Context missing source_type"
		result.error_type = "missing_source_type"
		result.recoverable = true  # Can set default source type
		return result
	
	# Validate each effect in the array with enhanced checking
	var invalid_effects = []
	for i in range(effects.size()):
		var effect = effects[i]
		
		if not is_instance_valid(effect):
			invalid_effects.append({"index": i, "reason": "null_effect"})
			continue
		
		if not effect is HandlerBase:
			invalid_effects.append({"index": i, "reason": "wrong_type", "type": effect.get_class()})
			continue
		
		if not effect.has_method("apply_effect"):
			invalid_effects.append({"index": i, "reason": "missing_apply_method"})
			continue
		
		if not effect.has_method("can_apply"):
			invalid_effects.append({"index": i, "reason": "missing_can_apply_method"})
			continue
		
		# Check for malformed effect data
		if _strict_validation:
			if effect.effect_id.is_empty():
				invalid_effects.append({"index": i, "reason": "empty_effect_id"})
	
	if not invalid_effects.is_empty():
		result.error_message = "Found %d invalid effects: %s" % [invalid_effects.size(), str(invalid_effects)]
		result.error_type = "invalid_effects"
		result.recoverable = _malformed_data_recovery  # Can attempt to filter out invalid effects
		return result
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Enhanced batch validation passed for %d effects" % effects.size())
	
	result.valid = true
	return result

## Enhanced validation for single effect inputs
func _validate_single_effect_inputs(effect: HandlerBase, context: HandlerContext) -> Dictionary:
	var result = {
		"valid": false,
		"error_message": "",
		"recoverable": false,
		"error_type": ""
	}
	
	# Check effect validity
	if not is_instance_valid(effect):
		result.error_message = "Invalid effect instance"
		result.error_type = "invalid_effect_instance"
		result.recoverable = false
		return result
	
	if not effect is HandlerBase:
		result.error_message = "Object is not a HandlerBase (type: %s)" % effect.get_class()
		result.error_type = "wrong_effect_type"
		result.recoverable = false
		return result
	
	# Check context validity
	if not is_instance_valid(context):
		result.error_message = "Invalid effect context"
		result.error_type = "invalid_context"
		result.recoverable = false
		return result
	
	if not context is HandlerContext:
		result.error_message = "Context is not an HandlerContext (type: %s)" % context.get_class()
		result.error_type = "wrong_context_type"
		result.recoverable = false
		return result
	
	# Check for required methods
	if not effect.has_method("apply_effect"):
		result.error_message = "Effect missing apply_effect method"
		result.error_type = "missing_apply_method"
		result.recoverable = false
		return result
	
	if not effect.has_method("can_apply"):
		result.error_message = "Effect missing can_apply method"
		result.error_type = "missing_can_apply_method"
		result.recoverable = false
		return result
	
	# Additional strict validation checks
	if _strict_validation:
		if effect.effect_id.is_empty():
			result.error_message = "Effect has empty effect_id"
			result.error_type = "empty_effect_id"
			result.recoverable = true  # Can generate a default ID
			return result
		
		if context.source_type.is_empty():
			result.error_message = "Context has empty source_type"
			result.error_type = "empty_source_type"
			result.recoverable = true  # Can set default source type
			return result
	
	result.valid = true
	return result

## Attempt to recover from batch validation failures
func _attempt_batch_recovery(effects: Array[HandlerBase], context: HandlerContext, validation_result: Dictionary) -> Dictionary:
	var recovery_result = {
		"success": false,
		"error_message": "",
		"recovery_action": "",
		"recovered_effects": effects,
		"recovered_context": context
	}
	
	match validation_result.error_type:
		"null_effects_array":
			var empty_effects: Array[HandlerBase] = []
			recovery_result.recovered_effects = empty_effects
			recovery_result.success = true
			recovery_result.recovery_action = "Created empty effects array"
		
		"missing_source_type":
			context.source_type = "unknown"
			recovery_result.recovered_context = context
			recovery_result.success = true
			recovery_result.recovery_action = "Set default source_type to 'unknown'"
		
		"invalid_effects":
			if _malformed_data_recovery:
				var filtered_effects: Array[HandlerBase] = []
				for i in range(effects.size()):
					var effect = effects[i]
					if is_instance_valid(effect) and effect is HandlerBase:
						filtered_effects.append(effect)
				
				recovery_result.recovered_effects = filtered_effects
				recovery_result.success = true
				recovery_result.recovery_action = "Filtered out %d invalid effects, %d remain" % [
					effects.size() - filtered_effects.size(), filtered_effects.size()
				]
			else:
				recovery_result.error_message = "Malformed data recovery disabled"
		
		_:
			recovery_result.error_message = "No recovery method available for error type: %s" % validation_result.error_type
	
	return recovery_result

## Attempt to recover from single effect validation failures
func _attempt_effect_recovery(effect: HandlerBase, context: HandlerContext, validation_result: Dictionary) -> Dictionary:
	var recovery_result = {
		"success": false,
		"error_message": "",
		"recovery_action": "",
		"recovered_effect": effect,
		"recovered_context": context
	}
	
	match validation_result.error_type:
		"empty_effect_id":
			if effect and effect.has_method("set"):
				effect.effect_id = "recovered_effect_%d" % Time.get_ticks_msec()
				recovery_result.recovered_effect = effect
				recovery_result.success = true
				recovery_result.recovery_action = "Generated default effect_id"
			else:
				recovery_result.error_message = "Cannot set effect_id on effect"
		
		"empty_source_type":
			context.source_type = "unknown"
			recovery_result.recovered_context = context
			recovery_result.success = true
			recovery_result.recovery_action = "Set default source_type to 'unknown'"
		
		_:
			recovery_result.error_message = "No recovery method available for error type: %s" % validation_result.error_type
	
	return recovery_result

## Validate an effect for processing with null safety
func _validate_effect_for_processing(effect: HandlerBase, index: int) -> bool:
	if not _null_safety_enabled:
		return true  # Skip validation if null safety is disabled
	
	if not is_instance_valid(effect):
		_safe_log("warn", "EffectProcessor: Null effect at index %d, skipping" % index)
		_stats.null_safety_activations += 1
		return false
	
	if not effect is HandlerBase:
		_safe_log("warn", "EffectProcessor: Non-HandlerBase at index %d (type: %s), skipping" % [index, effect.get_class()])
		_stats.null_safety_activations += 1
		return false
	
	if not effect.has_method("apply_effect") or not effect.has_method("can_apply"):
		_safe_log("warn", "EffectProcessor: Effect at index %d missing required methods, skipping" % index)
		_stats.null_safety_activations += 1
		return false
	
	return true

## Validate an HandlerResult for correctness
func _validate_effect_result(result: HandlerResult) -> bool:
	if not is_instance_valid(result):
		return false
	
	if not result is HandlerResult:
		return false
	
	# Check for required properties
	if not "success" in result:
		return false
	
	if not "values_applied" in result:
		return false
	
	if not "logs" in result:
		return false
	
	# Validate values_applied is a Dictionary
	if result.values_applied != null and not result.values_applied is Dictionary:
		return false
	
	# Validate logs is an Array
	if result.logs != null and not result.logs is Array:
		return false
	
	return true

## Recover a malformed HandlerResult
func _recover_malformed_result(malformed_result: HandlerResult, effect: HandlerBase) -> HandlerResult:
	var recovered = HandlerResult.new()
	
	# Try to preserve what we can from the malformed result
	if malformed_result and "success" in malformed_result:
		recovered.success = malformed_result.success
	else:
		recovered.success = false  # Default to failure for safety
	
	if malformed_result and "values_applied" in malformed_result and malformed_result.values_applied is Dictionary:
		recovered.values_applied = malformed_result.values_applied
	else:
		recovered.values_applied = {}
	
	if malformed_result and "logs" in malformed_result and malformed_result.logs is Array:
		recovered.logs = malformed_result.logs
	else:
		var empty_logs: Array[String] = []
		recovered.logs = empty_logs
	
	# Add recovery log
	recovered.logs.append("Result recovered from malformed data for effect: %s" % _safe_get_effect_id(effect))
	
	return recovered

## Create a default HandlerResult for recovery scenarios
func _create_default_effect_result(recovery_message: String) -> HandlerResult:
	var result = HandlerResult.new()
	result.success = false  # Default to failure for safety
	result.values_applied = {}
	var logs_array: Array[String] = [recovery_message]
	result.logs = logs_array
	return result

## Create a validation failure result
func _create_validation_failure_result(error_message: String) -> HandlerResult:
	var result = HandlerResult.new()
	result.success = false
	result.values_applied = {}
	var logs_array: Array[String] = ["Validation failed: " + error_message]
	result.logs = logs_array
	return result

## Safely get effect ID with null checking
func _safe_get_effect_id(effect: HandlerBase) -> String:
	if not is_instance_valid(effect):
		return "null_effect"
	
	if not "effect_id" in effect:
		return "no_id_property"
	
	if effect.effect_id.is_empty():
		return "empty_id"
	
	return effect.effect_id

## Extract failure reason from HandlerResult
func _extract_failure_reason(result: HandlerResult) -> String:
	if not result or not result.logs or result.logs.is_empty():
		return "Unknown failure reason"
	
	return result.logs[0]

## Determine if a failure is critical
func _is_critical_failure(result: HandlerResult) -> bool:
	if not result or not result.logs:
		return true  # Null result is always critical
	
	# Check for critical failure indicators in logs
	for log_entry in result.logs:
		var log_lower = log_entry.to_lower()
		if "exception" in log_lower or "crash" in log_lower or "critical" in log_lower:
			return true
		if "null" in log_lower and "result" in log_lower:
			return true
	
	return false

## Handle critical errors with appropriate logging and signaling
func _handle_critical_error(error_type: String, error_details: Dictionary) -> void:
	_stats.critical_errors += 1
	_critical_errors_count += 1
	
	_safe_log("error", "EffectProcessor: Critical error - %s: %s" % [error_type, str(error_details)])
	
	critical_error_detected.emit(error_type, error_details)
	
	# Add to debug trace if enabled
	if _debug_trace_enabled:
		_add_debug_trace("critical_error", {
			"error_type": error_type,
			"error_details": error_details,
			"timestamp": Time.get_ticks_msec()
		})

## Handle validation errors with appropriate logging and signaling
func _handle_validation_error(validation_type: String, error_message: String, object_info: Dictionary) -> void:
	_stats.validation_failures += 1
	
	_safe_log("warn", "EffectProcessor: Validation error - %s: %s" % [validation_type, error_message])
	
	validation_error.emit(validation_type, error_message, object_info)
	
	# Add to debug trace if enabled
	if _debug_trace_enabled:
		_add_debug_trace("validation_error", {
			"validation_type": validation_type,
			"error_message": error_message,
			"object_info": object_info,
			"timestamp": Time.get_ticks_msec()
		})

## Configure error handling and recovery settings
func configure_error_handling(config: Dictionary) -> void:
	if config.has("error_recovery_enabled"):
		_error_recovery_enabled = config.error_recovery_enabled
	
	if config.has("max_recovery_attempts"):
		_max_recovery_attempts = config.max_recovery_attempts
	
	if config.has("critical_error_threshold"):
		_critical_error_threshold = config.critical_error_threshold
	
	if config.has("strict_validation"):
		_strict_validation = config.strict_validation
	
	if config.has("allow_partial_batch_success"):
		_allow_partial_batch_success = config.allow_partial_batch_success
	
	if config.has("null_safety_enabled"):
		_null_safety_enabled = config.null_safety_enabled
	
	if config.has("malformed_data_recovery"):
		_malformed_data_recovery = config.malformed_data_recovery
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Error handling configuration updated: %s" % str(config))

## Get current error handling configuration
func get_error_handling_config() -> Dictionary:
	return {
		"error_recovery_enabled": _error_recovery_enabled,
		"max_recovery_attempts": _max_recovery_attempts,
		"critical_error_threshold": _critical_error_threshold,
		"strict_validation": _strict_validation,
		"allow_partial_batch_success": _allow_partial_batch_success,
		"null_safety_enabled": _null_safety_enabled,
		"malformed_data_recovery": _malformed_data_recovery,
		"current_critical_errors": _critical_errors_count
	}

## Reset error handling state
func reset_error_handling_state() -> void:
	_recovery_attempt_counts.clear()
	_critical_errors_count = 0
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Error handling state reset")

## Process card effects and return results directly as Array[HandlerResult]
func apply_card_instance_effects(duel_manager: DuelManager, card_instance: CardInstance) -> Array[HandlerResult]:
	return apply_card_instance_effects_with_context(duel_manager, card_instance, 0, 0)

## Process card effects with context and return results directly as Array[HandlerResult]
func apply_card_instance_effects_with_context(duel_manager: DuelManager, card_instance: CardInstance, cards_played_before: int, hand_size_before: int) -> Array[HandlerResult]:
	# Validate inputs - handle null inputs gracefully
	if not duel_manager or not card_instance:
		if DEBUG_ENABLED:
			_safe_log("error", "EffectProcessor: Invalid inputs for card effect processing")
		return []
	
	if not card_instance.card_data or not card_instance.card_data.effects:
		return []
	
	# Create context
	var context = create_context_for_card(card_instance, duel_manager)
	
	# Add timing information to context
	context.trigger_data["cards_played_this_turn"] = cards_played_before
	context.trigger_data["hand_size"] = hand_size_before
	
	# Process effects
	var typed_effects: Array[HandlerBase] = []
	for effect in card_instance.card_data.effects:
		if effect is HandlerBase:
			typed_effects.append(effect)
		else:
			_safe_log("warn", "EffectProcessor: Skipping non-HandlerBase in card effects: %s" % effect)
	
	var effect_results = process_effects(typed_effects, context)
	
	# Apply gambling modifiers directly to results if applicable
	_apply_gambling_modifiers_to_results(duel_manager, effect_results)
	
	return effect_results

## Apply gambling modifiers to Array[HandlerResult] directly
func _apply_gambling_modifiers_to_results(duel_manager: DuelManager, effect_results: Array[HandlerResult]) -> void:
	if not is_instance_valid(duel_manager) or not duel_manager.duel_state or not duel_manager.duel_state.player_data:
		return
	
	var player_data = duel_manager.duel_state.player_data
	
	if not player_data.has_method("check_and_apply_gambling"):
		return
	
	var gambling_result = player_data.check_and_apply_gambling()
	
	if not gambling_result is Dictionary or not gambling_result.has("active"):
		return
	
	if gambling_result.active:
		var multiplier = gambling_result.get("multiplier", 1.0)
		
		if DEBUG_ENABLED:
			_safe_log("debug", "EffectProcessor: Gambling active! Multiplier: %.1fx" % multiplier)
		
		# Query EventBus for gambling modifiers
		var context = {
			"success_chance": 0.5,
			"player_data": player_data
		}
		EventBus.gambling_modifier_query.emit(player_data, context)
		var success_chance = context.get("success_chance", 0.5)
		
		if SeedManager.get_combat_random_float() < success_chance:
			# Apply multiplier to relevant results
			var multiplied_fields = ["damage", "defense", "heal"]
			for result in effect_results:
				if not result.success:
					continue
				
				for field in multiplied_fields:
					if result.values_applied.has(field) and result.values_applied[field] is int:
						result.values_applied[field] = int(result.values_applied[field] * multiplier)
			
			if DEBUG_ENABLED:
				_safe_log("debug", "EffectProcessor: Gambling SUCCESS! Effects multiplied by %.1fx" % multiplier)
		else:
			# Negate effects on gambling failure
			for result in effect_results:
				if not result.success:
					continue
				
				# Zero out damage, defense, and heal effects
				if result.values_applied.has("damage"):
					result.values_applied["damage"] = 0
				if result.values_applied.has("defense"):
					result.values_applied["defense"] = 0
				if result.values_applied.has("heal"):
					result.values_applied["heal"] = 0
			
			if DEBUG_ENABLED:
				_safe_log("debug", "EffectProcessor: Gambling FAILED! All effects negated")





## Apply gambling modifiers for legacy compatibility
func _apply_gambling_modifiers(duel_manager: DuelManager, results: Dictionary) -> void:
	if not is_instance_valid(duel_manager) or not duel_manager.duel_state or not duel_manager.duel_state.player_data:
		return
	
	var player_data = duel_manager.duel_state.player_data
	
	if not player_data.has_method("check_and_apply_gambling"):
		return
	
	var gambling_result = player_data.check_and_apply_gambling()
	
	if not gambling_result is Dictionary or not gambling_result.has("active"):
		return
	
	if gambling_result.active:
		var multiplier = gambling_result.get("multiplier", 1.0)
		
		if DEBUG_ENABLED:
			_safe_log("debug", "EffectProcessor: Gambling active! Multiplier: %.1fx" % multiplier)
		
		# Query EventBus for gambling modifiers
		var context = {
			"success_chance": 0.5,
			"player_data": player_data
		}
		EventBus.gambling_modifier_query.emit(player_data, context)
		var success_chance = context.get("success_chance", 0.5)
		
		if SeedManager.get_combat_random_float() < success_chance:
			# Apply multiplier to relevant results
			var multiplied_fields = ["damage", "defense", "heal"]
			for field in multiplied_fields:
				if results.has(field) and results[field] is int:
					results[field] = int(results[field] * multiplier)
			
			if DEBUG_ENABLED:
				_safe_log("debug", "EffectProcessor: Gambling SUCCESS! Effects multiplied by %.1fx" % multiplier)
		else:
			# Negate effects on gambling failure
			results.damage = 0
			results.defense = 0
			results.heal = 0
			
			if DEBUG_ENABLED:
				_safe_log("debug", "EffectProcessor: Gambling FAILED! All effects negated")

## Sort effects for deterministic processing
func _sort_effects_for_deterministic_processing(effects: Array[HandlerBase]) -> Array[HandlerBase]:
	"""Sort effects by their effect_id to ensure consistent processing order.
	
	This ensures that identical effect arrays are always processed in the same order,
	which is crucial for deterministic behavior.
	
	Args:
		effects: Array of HandlerBase instances to sort
		
	Returns:
		New array with effects sorted by effect_id
	"""
	if not _deterministic_mode or effects.size() <= 1:
		return effects
	
	# Create a copy to avoid modifying the original array
	var sorted_effects = effects.duplicate()
	
	# Sort by effect_id using a stable sort
	sorted_effects.sort_custom(func(a: HandlerBase, b: HandlerBase) -> bool:
		var id_a = _safe_get_effect_id(a)
		var id_b = _safe_get_effect_id(b)
		
		# Handle cases where IDs might be empty or identical
		if id_a == id_b:
			# Fall back to memory address for consistent ordering of identical IDs
			return a.get_instance_id() < b.get_instance_id()
		
		return id_a < id_b
	)
	
	return sorted_effects

## Validate deterministic processing by running effects multiple times
func validate_deterministic_processing(effects: Array[HandlerBase], context: HandlerContext, iterations: int = 3) -> Dictionary:
	"""Validate that effect processing produces consistent results across multiple runs.
	
	This method processes the same effects multiple times and compares results to ensure
	deterministic behavior. Used for testing and validation.
	
	Args:
		effects: Array of effects to test
		context: Context for processing
		iterations: Number of times to run the test (default: 3)
		
	Returns:
		Dictionary with validation results:
		- deterministic: bool - whether results were consistent
		- results: Array of result sets from each iteration
		- differences: Array of any differences found
	"""
	var validation_result = {
		"deterministic": true,
		"results": [],
		"differences": [],
		"iterations_run": 0
	}
	
	if not _deterministic_mode:
		validation_result.deterministic = false
		validation_result.differences.append("Deterministic mode is disabled")
		return validation_result
	
	if effects.is_empty():
		validation_result.deterministic = true
		return validation_result
	
	# Store original validation setting
	var original_validation = _validate_deterministic_results
	_validate_deterministic_results = false  # Disable to avoid recursion
	
	# Run processing multiple times
	for i in range(iterations):
		var results = process_effects(effects, context)
		validation_result.results.append(_serialize_results_for_comparison(results))
		validation_result.iterations_run += 1
		
		# Compare with first result
		if i > 0:
			var differences = _compare_result_sets(validation_result.results[0], validation_result.results[i])
			if not differences.is_empty():
				validation_result.deterministic = false
				validation_result.differences.append_array(differences)
	
	# Restore original validation setting
	_validate_deterministic_results = original_validation
	
	if DEBUG_ENABLED:
		if validation_result.deterministic:
			_safe_log("debug", "EffectProcessor: Deterministic validation PASSED for %d effects over %d iterations" % [effects.size(), iterations])
		else:
			_safe_log("warn", "EffectProcessor: Deterministic validation FAILED - found %d differences" % validation_result.differences.size())
			for diff in validation_result.differences:
				_safe_log("warn", "  - %s" % diff)
	
	return validation_result

## Serialize results for comparison in deterministic validation
func _serialize_results_for_comparison(results: Array[HandlerResult]) -> Array[Dictionary]:
	"""Convert HandlerResult array to comparable format for deterministic validation."""
	var serialized = []
	
	for result in results:
		if not result:
			serialized.append({"null_result": true})
			continue
		
		var serialized_result = {
			"success": result.success,
			"values_applied": result.values_applied.duplicate() if result.values_applied else {},
			"logs": result.logs.duplicate() if result.logs else []
		}
		
		# Sort logs for consistent comparison (logs might be added in different orders)
		if serialized_result.logs is Array:
			serialized_result.logs.sort()
		
		serialized.append(serialized_result)
	
	return serialized

## Compare two result sets for differences
func _compare_result_sets(results_a: Array, results_b: Array) -> Array[String]:
	"""Compare two serialized result sets and return list of differences."""
	var differences = []
	
	if results_a.size() != results_b.size():
		differences.append("Result count differs: %d vs %d" % [results_a.size(), results_b.size()])
		return differences
	
	for i in range(results_a.size()):
		var result_a = results_a[i]
		var result_b = results_b[i]
		
		# Compare success status
		if result_a.get("success", false) != result_b.get("success", false):
			differences.append("Result %d success differs: %s vs %s" % [i, result_a.get("success"), result_b.get("success")])
		
		# Compare values_applied
		var values_a = result_a.get("values_applied", {})
		var values_b = result_b.get("values_applied", {})
		
		if values_a.size() != values_b.size():
			differences.append("Result %d values count differs: %d vs %d" % [i, values_a.size(), values_b.size()])
		else:
			for key in values_a.keys():
				if not values_b.has(key):
					differences.append("Result %d missing key '%s' in second result" % [i, key])
				elif values_a[key] != values_b[key]:
					differences.append("Result %d key '%s' differs: %s vs %s" % [i, key, values_a[key], values_b[key]])
		
		# Compare logs (already sorted in serialization)
		var logs_a = result_a.get("logs", [])
		var logs_b = result_b.get("logs", [])
		
		if logs_a.size() != logs_b.size():
			differences.append("Result %d log count differs: %d vs %d" % [i, logs_a.size(), logs_b.size()])
		else:
			for j in range(logs_a.size()):
				if logs_a[j] != logs_b[j]:
					differences.append("Result %d log %d differs: '%s' vs '%s'" % [i, j, logs_a[j], logs_b[j]])
	
	return differences

## Configure deterministic processing settings
func configure_deterministic_processing(config: Dictionary) -> void:
	"""Configure deterministic processing behavior.
	
	Args:
		config: Dictionary with configuration options:
		- deterministic_mode: bool - Enable/disable deterministic processing
		- sort_effects_by_id: bool - Sort effects by ID for consistent order
		- validate_deterministic_results: bool - Validate results are deterministic
	"""
	if config.has("deterministic_mode"):
		_deterministic_mode = config.deterministic_mode
	
	if config.has("sort_effects_by_id"):
		_sort_effects_by_id = config.sort_effects_by_id
	
	if config.has("validate_deterministic_results"):
		_validate_deterministic_results = config.validate_deterministic_results
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Deterministic processing configured: %s" % str(config))

## Get current deterministic processing configuration
func get_deterministic_processing_config() -> Dictionary:
	"""Get current deterministic processing configuration."""
	return {
		"deterministic_mode": _deterministic_mode,
		"sort_effects_by_id": _sort_effects_by_id,
		"validate_deterministic_results": _validate_deterministic_results
	}

# ============================================================================
# BATCH PROCESSING OPTIMIZATION METHODS
# ============================================================================

## Get an HandlerResult from the object pool or create a new one
func _get_pooled_effect_result() -> HandlerResult:
	"""Get a reusable HandlerResult from the object pool to minimize allocations."""
	if not _object_pool_enabled or _effect_result_pool.is_empty():
		return HandlerResult.new()
	
	var result = _effect_result_pool.pop_back()
	
	# Reset the result to clean state
	result.success = false
	result.values_applied = {}
	var empty_logs: Array[String] = []
	result.logs = empty_logs
	
	_batch_performance_stats.objects_pooled += 1
	return result

## Return an HandlerResult to the object pool for reuse
func _return_pooled_effect_result(result: HandlerResult) -> void:
	"""Return an HandlerResult to the pool for reuse if pool is not full."""
	if not _object_pool_enabled or _effect_result_pool.size() >= _max_pool_size:
		return
	
	# Clean the result before returning to pool
	result.success = false
	result.values_applied.clear()
	result.logs.clear()
	
	_effect_result_pool.append(result)

## Get an HandlerContext from the object pool or create a new one
func _get_pooled_context() -> HandlerContext:
	"""Get a reusable HandlerContext from the object pool to minimize allocations."""
	if not _object_pool_enabled or _context_pool.is_empty():
		var context = HandlerContext.new()
		return context
	
	var context = _context_pool.pop_back()
	
	# Mark as taken from pool for performance tracking
	context.mark_taken_from_pool()
	
	_batch_performance_stats.objects_pooled += 1
	return context

## Return an HandlerContext to the object pool for reuse
func _return_pooled_context(context: HandlerContext) -> void:
	"""Return an HandlerContext to the pool for reuse if pool is not full."""
	if not _object_pool_enabled or _context_pool.size() >= _max_pool_size:
		return
	
	# Use the context's reset method for proper cleanup
	context.reset_for_reuse()
	
	_context_pool.append(context)

## Batch validate effects with caching to avoid redundant validation
func _batch_validate_effects(effects: Array[HandlerBase]) -> Array[bool]:
	"""Pre-validate all effects in a batch and cache results to avoid redundant checks."""
	var validations: Array[bool] = []
	validations.resize(effects.size())
	
	for i in range(effects.size()):
		var effect = effects[i]
		var effect_id = _safe_get_effect_id(effect)
		
		# Check validation cache first
		if _validation_cache.has(effect_id):
			validations[i] = _validation_cache[effect_id]
			_batch_performance_stats.validation_cache_hits += 1
		else:
			# Perform validation and cache result
			var is_valid = _validate_effect_for_processing(effect, i)
			validations[i] = is_valid
			
			# Cache the result if cache is not full
			if _validation_cache.size() < _validation_cache_max_size:
				_validation_cache[effect_id] = is_valid
	
	return validations

## Enhanced batch input validation with caching
func _validate_batch_inputs_cached(effects: Array[HandlerBase], context: HandlerContext) -> Dictionary:
	"""Validate batch inputs with caching to improve performance for repeated validations."""
	# Create a cache key based on effect count and context type
	var cache_key = "%d_effects_%s" % [effects.size(), context.source_type if context else "null"]
	
	# Check if we've validated this pattern before
	if _validation_cache_enabled and _validation_cache.has(cache_key):
		var cached_result = _validation_cache[cache_key].duplicate()  # Duplicate to avoid reference issues
		_batch_performance_stats.validation_cache_hits += 1
		
		# For cached results, we still need to do basic null checks
		if not effects or not context:
			cached_result.valid = false
			cached_result.error_message = "Null inputs detected"
		
		return cached_result
	
	# Perform full validation
	var result = _validate_batch_inputs_enhanced(effects, context)
	
	# Cache the result pattern if cache is not full
	if _validation_cache_enabled and _validation_cache.size() < _validation_cache_max_size:
		_validation_cache[cache_key] = result.duplicate()
	
	return result

## Optimized single effect processing with object pooling
func _process_single_effect_optimized(effect: HandlerBase, context: HandlerContext, result: HandlerResult) -> HandlerResult:
	"""Process a single effect with optimizations like reduced validation and object reuse."""
	var effect_start_time = Time.get_ticks_msec()
	
	# Skip redundant validation since we've already batch-validated
	if DEBUG_ENABLED:
		_safe_log("trace", "EffectProcessor: Processing optimized effect %s" % _safe_get_effect_id(effect))
	
	# Check if effect can be applied (this is still necessary for game logic)
	var can_apply_start_time = Time.get_ticks_msec()
	var can_apply_result: bool = false
	
	if effect.has_method("can_apply"):
		can_apply_result = effect.can_apply(context)
	else:
		result.success = false
		result.logs.append("Effect missing can_apply method")
		return result
	
	if not can_apply_result:
		result.success = false
		result.logs.append("Effect cannot be applied in current context")
		return result
	
	# Apply the effect
	var apply_start_time = Time.get_ticks_msec()
	var apply_result: HandlerResult = null
	
	if effect.has_method("apply_effect"):
		apply_result = effect.apply_effect(context)
	else:
		result.success = false
		result.logs.append("Effect missing apply_effect method")
		return result
	
	# Copy results to our pooled result object to avoid additional allocations
	if apply_result:
		result.success = apply_result.success
		result.values_applied = apply_result.values_applied.duplicate() if apply_result.values_applied else {}
		result.logs = apply_result.logs.duplicate() if apply_result.logs else []
	else:
		result.success = false
		result.logs.append("Effect returned null result")
	
	return result

## Configure batch processing optimization settings
func configure_batch_optimization(config: Dictionary) -> void:
	"""Configure batch processing optimization settings.
	
	Args:
		config: Dictionary with optimization settings:
		- batch_optimization_enabled: bool - Enable/disable batch optimizations
		- batch_size_threshold: int - Minimum batch size to trigger optimizations
		- object_pool_enabled: bool - Enable/disable object pooling
		- validation_cache_enabled: bool - Enable/disable validation caching
		- max_pool_size: int - Maximum size for object pools
		- validation_cache_max_size: int - Maximum size for validation cache
	"""
	if config.has("batch_optimization_enabled"):
		_batch_optimization_enabled = config.batch_optimization_enabled
	
	if config.has("batch_size_threshold"):
		_batch_size_threshold = max(1, config.batch_size_threshold)
	
	if config.has("object_pool_enabled"):
		_object_pool_enabled = config.object_pool_enabled
		if not _object_pool_enabled:
			# Clear pools if disabled
			_effect_result_pool.clear()
			_context_pool.clear()
	
	if config.has("validation_cache_enabled"):
		_validation_cache_enabled = config.validation_cache_enabled
		if not _validation_cache_enabled:
			_validation_cache.clear()
	
	if config.has("max_pool_size"):
		_max_pool_size = max(10, config.max_pool_size)
		# Trim pools if they're too large
		while _effect_result_pool.size() > _max_pool_size:
			_effect_result_pool.pop_back()
		while _context_pool.size() > _max_pool_size:
			_context_pool.pop_back()
	
	if config.has("validation_cache_max_size"):
		_validation_cache_max_size = max(50, config.validation_cache_max_size)
		# Trim cache if it's too large
		while _validation_cache.size() > _validation_cache_max_size:
			var keys = _validation_cache.keys()
			_validation_cache.erase(keys[0])
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Batch optimization configured: %s" % str(config))

## Get current batch optimization configuration
func get_batch_optimization_config() -> Dictionary:
	"""Get current batch optimization configuration."""
	return {
		"batch_optimization_enabled": _batch_optimization_enabled,
		"batch_size_threshold": _batch_size_threshold,
		"object_pool_enabled": _object_pool_enabled,
		"validation_cache_enabled": _validation_cache_enabled,
		"max_pool_size": _max_pool_size,
		"validation_cache_max_size": _validation_cache_max_size,
		"current_result_pool_size": _effect_result_pool.size(),
		"current_context_pool_size": _context_pool.size(),
		"current_validation_cache_size": _validation_cache.size()
	}

## Get batch performance statistics
func get_batch_performance_stats() -> Dictionary:
	"""Get performance statistics for batch processing optimizations."""
	var stats = _batch_performance_stats.duplicate()
	
	# Add calculated metrics
	if _stats.batch_count > 0:
		stats["optimization_rate"] = float(_batch_performance_stats.batches_optimized) / float(_stats.batch_count)
	else:
		stats["optimization_rate"] = 0.0
	
	if _batch_performance_stats.validation_cache_hits > 0:
		var total_validations = _batch_performance_stats.validation_cache_hits + (_stats.total_effects_processed - _batch_performance_stats.validation_cache_hits)
		stats["cache_hit_rate"] = float(_batch_performance_stats.validation_cache_hits) / float(total_validations)
	else:
		stats["cache_hit_rate"] = 0.0
	
	return stats

## Reset batch performance statistics
func reset_batch_performance_stats() -> void:
	"""Reset batch processing performance statistics."""
	_batch_performance_stats = {
		"batches_optimized": 0,
		"objects_pooled": 0,
		"validation_cache_hits": 0,
		"allocation_savings": 0,
		"processing_time_saved_ms": 0
	}
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Batch performance statistics reset")

## Clear all optimization caches and pools
func clear_optimization_caches() -> void:
	"""Clear all optimization caches and object pools."""
	_validation_cache.clear()
	_effect_result_pool.clear()
	_context_pool.clear()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Optimization caches and pools cleared")

## Benchmark batch processing performance
func benchmark_batch_processing(effect_counts: Array[int], iterations: int = 10) -> Dictionary:
	"""Benchmark batch processing performance with different effect counts and optimization settings.
	
	Args:
		effect_counts: Array of effect counts to test (e.g., [1, 5, 10, 25, 50])
		iterations: Number of iterations per test
		
	Returns:
		Dictionary with benchmark results including timing comparisons
	"""
	var benchmark_results = {
		"test_timestamp": Time.get_datetime_string_from_system(),
		"iterations_per_test": iterations,
		"results": {}
	}
	
	# Store original settings
	var original_optimization = _batch_optimization_enabled
	var original_threshold = _batch_size_threshold
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Starting batch processing benchmark with %d effect counts" % effect_counts.size())
	
	for effect_count in effect_counts:
		var test_key = "effects_%d" % effect_count
		benchmark_results.results[test_key] = {
			"effect_count": effect_count,
			"optimized_times": [],
			"standard_times": [],
			"optimized_avg": 0.0,
			"standard_avg": 0.0,
			"performance_improvement": 0.0
		}
		
		# Create test effects (simple damage effects for consistency)
		var test_effects: Array[HandlerBase] = []
		for i in range(effect_count):
			var effect = DamageHandler.new()
			effect.effect_id = "benchmark_effect_%d" % i
			effect.damage_amount = 1
			test_effects.append(effect)
		
		# Create test context
		var test_context = HandlerContext.new()
		test_context.source_type = "benchmark"
		test_context.trigger_event = "benchmark_test"
		
		# Test with optimizations enabled
		_batch_optimization_enabled = true
		_batch_size_threshold = 1  # Always use optimizations
		
		for i in range(iterations):
			var start_time = Time.get_ticks_msec()
			process_effects(test_effects, test_context)
			var end_time = Time.get_ticks_msec()
			benchmark_results.results[test_key].optimized_times.append(end_time - start_time)
		
		# Test with optimizations disabled
		_batch_optimization_enabled = false
		
		for i in range(iterations):
			var start_time = Time.get_ticks_msec()
			process_effects(test_effects, test_context)
			var end_time = Time.get_ticks_msec()
			benchmark_results.results[test_key].standard_times.append(end_time - start_time)
		
		# Calculate averages
		var optimized_total = 0
		for time in benchmark_results.results[test_key].optimized_times:
			optimized_total += time
		benchmark_results.results[test_key].optimized_avg = float(optimized_total) / float(iterations)
		
		var standard_total = 0
		for time in benchmark_results.results[test_key].standard_times:
			standard_total += time
		benchmark_results.results[test_key].standard_avg = float(standard_total) / float(iterations)
		
		# Calculate performance improvement
		if benchmark_results.results[test_key].standard_avg > 0:
			var improvement = (benchmark_results.results[test_key].standard_avg - benchmark_results.results[test_key].optimized_avg) / benchmark_results.results[test_key].standard_avg
			benchmark_results.results[test_key].performance_improvement = improvement * 100.0
		
		if DEBUG_ENABLED:
			_safe_log("debug", "EffectProcessor: Benchmark %d effects - Optimized: %.1fms, Standard: %.1fms, Improvement: %.1f%%" % [
				effect_count,
				benchmark_results.results[test_key].optimized_avg,
				benchmark_results.results[test_key].standard_avg,
				benchmark_results.results[test_key].performance_improvement
			])
	
	# Restore original settings
	_batch_optimization_enabled = original_optimization
	_batch_size_threshold = original_threshold
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Batch processing benchmark completed")
	
	return benchmark_results

## Initialize object pools with pre-allocated objects for better performance
func _initialize_object_pools() -> void:
	"""Pre-allocate objects in pools to reduce initial allocation overhead."""
	if not _object_pool_enabled:
		return
	
	# Pre-warm context pool
	for i in range(_pool_warmup_size):
		var context = HandlerContext.new()
		context.reset_for_reuse()
		_context_pool.append(context)
	
	# Pre-warm effect result pool
	for i in range(_pool_warmup_size):
		var result = HandlerResult.new()
		result.success = false
		result.values_applied = {}
		var empty_logs: Array[String] = []
		result.logs = empty_logs
		_effect_result_pool.append(result)
	
	if DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Object pools initialized with %d pre-allocated objects each" % _pool_warmup_size)

## Manage pool sizes to prevent excessive memory usage
func _manage_pool_sizes() -> void:
	"""Shrink pools if they grow too large to prevent memory bloat."""
	var pools_shrunk = false
	
	# Shrink context pool if needed
	if _context_pool.size() > _pool_shrink_threshold:
		var excess = _context_pool.size() - _max_pool_size
		for i in range(excess):
			_context_pool.pop_back()
		pools_shrunk = true
	
	# Shrink effect result pool if needed
	if _effect_result_pool.size() > _pool_shrink_threshold:
		var excess = _effect_result_pool.size() - _max_pool_size
		for i in range(excess):
			_effect_result_pool.pop_back()
		pools_shrunk = true
	
	if pools_shrunk and DEBUG_ENABLED:
		_safe_log("debug", "EffectProcessor: Object pools shrunk to prevent memory bloat")

## Get comprehensive pool statistics for monitoring
func get_pool_statistics() -> Dictionary:
	"""Get detailed statistics about object pool usage and efficiency."""
	return {
		"context_pool": {
			"size": _context_pool.size(),
			"max_size": _max_pool_size,
			"warmup_size": _pool_warmup_size,
			"shrink_threshold": _pool_shrink_threshold,
			"utilization": float(_context_pool.size()) / float(_max_pool_size) if _max_pool_size > 0 else 0.0
		},
		"effect_result_pool": {
			"size": _effect_result_pool.size(),
			"max_size": _max_pool_size,
			"warmup_size": _pool_warmup_size,
			"shrink_threshold": _pool_shrink_threshold,
			"utilization": float(_effect_result_pool.size()) / float(_max_pool_size) if _max_pool_size > 0 else 0.0
		},
		"performance": _batch_performance_stats,
		"enabled": _object_pool_enabled
	}

## Configure pool settings for different performance profiles
func configure_pool_settings(profile: String) -> void:
	"""Configure object pool settings based on performance profile."""
	match profile:
		"memory_conservative":
			_max_pool_size = 25
			_pool_warmup_size = 5
			_pool_shrink_threshold = 35
		"balanced":
			_max_pool_size = 50
			_pool_warmup_size = 10
			_pool_shrink_threshold = 75
		"performance_focused":
			_max_pool_size = 100
			_pool_warmup_size = 20
			_pool_shrink_threshold = 150
		_:
			_safe_log("warn", "EffectProcessor: Unknown pool profile '%s', using balanced settings" % profile)
			configure_pool_settings("balanced")
			return
	
	# Re-initialize pools with new settings
	_context_pool.clear()
	_effect_result_pool.clear()
	_initialize_object_pools()
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Pool settings configured for '%s' profile" % profile)

## Called when the processor is ready to initialize
func _ready() -> void:
	"""Initialize the effect processor and its object pools."""
	_initialize_object_pools()
	
	# Set up periodic pool management
	var timer = Timer.new()
	timer.wait_time = 30.0  # Check every 30 seconds
	timer.timeout.connect(_manage_pool_sizes)
	timer.autostart = true
	add_child(timer)
	
	if DEBUG_ENABLED:
		_safe_log("info", "EffectProcessor: Initialized with object pooling %s" % ("enabled" if _object_pool_enabled else "disabled"))
