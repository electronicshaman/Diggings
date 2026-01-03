extends Node
class_name EffectProcessor

const DEBUG_ENABLED: bool = true

# Signals for effect processing events
signal effect_executed(effect: GameEffect, result: EffectResult, context: EffectContext)
signal effect_failed(effect: GameEffect, reason: String, context: EffectContext)
signal batch_completed(results: Array[EffectResult])

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
	"effects_sorted_for_determinism": 0
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

## Process multiple effects in batch
func process_effects(effects: Array[GameEffect], context: EffectContext) -> Array[EffectResult]:
	var batch_start_time = Time.get_ticks_msec()
	var results: Array[EffectResult] = []
	
	# Enhanced input validation with graceful error handling
	var validation_result = _validate_batch_inputs_enhanced(effects, context)
	if not validation_result.valid:
		GLog.error("EffectProcessor: Batch validation failed - %s" % validation_result.error_message)
		_stats.validation_failures += 1
		
		# Attempt recovery if enabled
		if _error_recovery_enabled and validation_result.recoverable:
			var recovery_result = _attempt_batch_recovery(effects, context, validation_result)
			if recovery_result.success:
				GLog.warn("EffectProcessor: Batch validation recovered - %s" % recovery_result.recovery_action)
				_stats.error_recoveries += 1
				error_recovered.emit("batch_validation", recovery_result.recovery_action, {
					"original_error": validation_result.error_message,
					"effect_count": effects.size() if effects else 0
				})
				# Continue with recovered data
				effects = recovery_result.recovered_effects
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
		GLog.debug("EffectProcessor: Starting batch processing of %d effects from %s" % [effects.size(), context.source_type])
		_log_context_details(context, "batch_start")
	
	# Ensure deterministic processing order if enabled
	var processing_effects = effects
	if _deterministic_mode and _sort_effects_by_id:
		processing_effects = _sort_effects_for_deterministic_processing(effects)
		if DEBUG_ENABLED and processing_effects != effects:
			GLog.debug("EffectProcessor: Effects sorted for deterministic processing")
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
			GLog.trace("EffectProcessor: Processing effect %d/%d: %s" % [i + 1, processing_effects.size(), _safe_get_effect_id(effect)])
		
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
				GLog.warn("EffectProcessor: Slow effect processing detected - %s took %dms" % [_safe_get_effect_id(effect), effect_processing_time])
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
					GLog.debug("EffectProcessor: Effect %d (%s) succeeded in %dms" % [i, _safe_get_effect_id(effect), effect_processing_time])
					_log_effect_result_details(effect, result, effect_processing_time)
			else:
				failed_count += 1
				_stats.failed_effects += 1
				
				if is_critical:
					critical_failures += 1
				
				var reason = _extract_failure_reason(result)
				effect_failed.emit(effect, reason, context)
				
				GLog.warn("EffectProcessor: Effect %d (%s) failed in %dms: %s%s" % [
					i, _safe_get_effect_id(effect), effect_processing_time, reason,
					" [CRITICAL]" if is_critical else ""
				])
				
				# Enhanced failure logging
				if DEBUG_ENABLED:
					_log_effect_failure_details(effect, result, context, effect_processing_time)
				
				# Check if we should abort batch processing due to critical failures
				if not _allow_partial_batch_success and is_critical:
					GLog.error("EffectProcessor: Aborting batch due to critical failure in effect %d" % i)
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
			
			GLog.warn("EffectProcessor: Effect %d failed validation and was skipped" % i)
			
			# Check if we should abort due to validation failures
			if not _allow_partial_batch_success:
				GLog.error("EffectProcessor: Aborting batch due to validation failure in effect %d" % i)
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
		GLog.warn("EffectProcessor: Slow batch processing detected - %d effects took %dms" % [processing_effects.size(), total_batch_time])
		performance_warning.emit("batch_processing", total_batch_time, _performance_thresholds.batch_processing_ms)
	
	# Enhanced completion logging
	if DEBUG_ENABLED:
		GLog.debug("EffectProcessor: Batch complete - %d processed, %d failed (%d critical) in %dms (avg: %.1fms per effect)" % [
			processed_count, failed_count, critical_failures, total_batch_time, 
			float(batch_processing_time) / float(processing_effects.size()) if processing_effects.size() > 0 else 0.0
		])
		
		# Log performance summary
		_log_batch_performance_summary(processing_effects.size(), total_batch_time, batch_processing_time)
	
	# Check for critical error threshold
	if _critical_errors_count >= _critical_error_threshold:
		GLog.error("EffectProcessor: Critical error threshold reached (%d/%d)" % [_critical_errors_count, _critical_error_threshold])
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
func process_single_effect(effect: GameEffect, context: EffectContext) -> EffectResult:
	var effect_start_time = Time.get_ticks_msec()
	var result = EffectResult.new()
	
	# Enhanced validation with detailed error reporting and recovery
	var validation_result = _validate_single_effect_inputs(effect, context)
	if not validation_result.valid:
		result.success = false
		result.logs.append(validation_result.error_message)
		
		# Attempt recovery if enabled and possible
		if _error_recovery_enabled and validation_result.recoverable:
			var recovery_result = _attempt_effect_recovery(effect, context, validation_result)
			if recovery_result.success:
				GLog.warn("EffectProcessor: Effect validation recovered - %s" % recovery_result.recovery_action)
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
				GLog.error("EffectProcessor: Effect validation failed and recovery unsuccessful - %s" % validation_result.error_message)
				_stats.validation_failures += 1
				_handle_validation_error("effect_validation", validation_result.error_message, {
					"effect_id": _safe_get_effect_id(effect),
					"effect_type": effect.get_class() if effect else "null",
					"context_type": context.source_type if context else "null"
				})
				return result
		else:
			# No recovery attempted
			GLog.error("EffectProcessor: Effect validation failed - %s" % validation_result.error_message)
			_stats.validation_failures += 1
			_handle_validation_error("effect_validation", validation_result.error_message, {
				"effect_id": _safe_get_effect_id(effect),
				"recovery_enabled": _error_recovery_enabled
			})
			return result
	
	# Enhanced debug logging with more context information
	if DEBUG_ENABLED:
		GLog.debug("EffectProcessor: Processing effect %s from %s (target: %s)" % [
			_safe_get_effect_id(effect), 
			context.source_type,
			_get_target_description(context.primary_target)
		])
		
		# Log additional context details for debugging
		if GLog.min_log_level <= GLog.Level.TRACE:
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
		GLog.error("EffectProcessor: Effect %s missing can_apply method" % _safe_get_effect_id(effect))
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
			GLog.debug("EffectProcessor: Effect %s cannot be applied - conditions not met (check took %dms)" % [_safe_get_effect_id(effect), can_apply_time])
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
	var apply_result: EffectResult = null
	
	# Safely call apply_effect with comprehensive error handling
	if effect.has_method("apply_effect"):
		apply_result = effect.apply_effect(context)
	else:
		GLog.error("EffectProcessor: Effect %s missing apply_effect method" % _safe_get_effect_id(effect))
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
		GLog.error("EffectProcessor: Effect %s returned null result (apply took %dms)" % [_safe_get_effect_id(effect), apply_time])
		
		# Attempt to create a default result if malformed data recovery is enabled
		if _malformed_data_recovery:
			result = _create_default_effect_result("Null result recovered with default values")
			_stats.malformed_data_encountered += 1
			GLog.warn("EffectProcessor: Created default result for null return from effect %s" % _safe_get_effect_id(effect))
		
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
				GLog.warn("EffectProcessor: Recovered malformed result from effect %s" % _safe_get_effect_id(effect))
			else:
				result.success = false
				result.logs.append("Malformed result could not be recovered")
				GLog.error("EffectProcessor: Effect %s returned malformed result that could not be recovered" % _safe_get_effect_id(effect))
		else:
			result.success = false
			result.logs.append("Effect returned malformed result")
			GLog.error("EffectProcessor: Effect %s returned malformed result" % _safe_get_effect_id(effect))
	elif not apply_result.success:
		result = apply_result
		result.logs.append("Effect application failed")
		GLog.warn("EffectProcessor: Effect %s application failed (apply took %dms)" % [_safe_get_effect_id(effect), apply_time])
		
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
		GLog.debug("EffectProcessor: Effect %s processing breakdown - can_apply: %dms, apply: %dms, total: %dms" % [
			_safe_get_effect_id(effect), can_apply_time, apply_time, total_effect_time
		])
	
	return result

## Create context for card effects
func create_context_for_card(card_instance: CardInstance, duel_manager: DuelManager) -> EffectContext:
	var context_start_time = Time.get_ticks_msec()
	
	if DEBUG_ENABLED:
		GLog.trace("EffectProcessor: Creating card context for %s" % (card_instance.card_data.card_name if card_instance and card_instance.card_data else "unknown"))
	
	if not is_instance_valid(card_instance):
		GLog.error("EffectProcessor: Cannot create context - invalid card_instance")
		_stats.validation_failures += 1
		return null
	
	if not is_instance_valid(duel_manager):
		GLog.error("EffectProcessor: Cannot create context - invalid duel_manager")
		_stats.validation_failures += 1
		return null
	
	var context = EffectContext.new()
	
	# Set source information
	context.source_type = "card"
	context.source_object = card_instance.card_data if card_instance else null
	
	# Set state references
	context.duel_manager = duel_manager
	if duel_manager and duel_manager.duel_state:
		context.player_data = duel_manager.duel_state.player_data
		context.enemy_data = duel_manager.duel_state.enemy_data
	else:
		GLog.warn("EffectProcessor: DuelManager has no duel_state when creating card context")
	
	# Set trigger information
	context.trigger_event = "card_played"
	context.trigger_data = {
		"card_instance": card_instance,
		"duel_state": duel_manager.duel_state if duel_manager else null
	}
	
	# Set targeting based on card ownership and type
	if card_instance and card_instance.card_data:
		var is_player_owned = card_instance.owner == CardInstance.Owner.PLAYER
		var card_type = card_instance.card_data.get_mechanical_category() if card_instance.card_data.has_method("get_mechanical_category") else ""
		
		# Attack cards target the opponent, other cards typically target self
		if card_type == "Attack":
			context.primary_target = context.enemy_data if is_player_owned else context.player_data
		else:
			context.primary_target = context.player_data if is_player_owned else context.enemy_data
		
		if DEBUG_ENABLED:
			GLog.debug("EffectProcessor: Created card context - owner: %s, type: %s, target: %s" % [
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
				GLog.trace("EffectProcessor: Applied %d curio modifications to card context" % context.curio_modifications.size())
		else:
			GLog.warn("EffectProcessor: CurioManager missing calculate_card_modifications method")
	
	var curio_time = Time.get_ticks_msec() - curio_start_time
	var total_context_time = Time.get_ticks_msec() - context_start_time
	
	# Update performance statistics
	_stats.context_creation_time_ms += total_context_time
	
	# Check for performance warnings
	if total_context_time > _performance_thresholds.context_creation_ms:
		GLog.warn("EffectProcessor: Slow card context creation - took %dms (curio lookup: %dms)" % [total_context_time, curio_time])
		performance_warning.emit("context_creation", total_context_time, _performance_thresholds.context_creation_ms)
	
	# Add debug trace
	if _debug_trace_enabled:
		_add_debug_trace("card_context_created", {
			"card_name": card_instance.card_data.card_name if card_instance.card_data else "unknown",
			"creation_time_ms": total_context_time,
			"curio_modifications": context.curio_modifications.size(),
			"timestamp": Time.get_ticks_msec()
		})
	
	if DEBUG_ENABLED and GLog.min_log_level <= GLog.Level.TRACE:
		GLog.trace("EffectProcessor: Card context creation complete in %dms" % total_context_time)
	
	return context

## Create context for encounter effects
func create_context_for_encounter(encounter: EncounterData, player_data: PlayerData) -> EffectContext:
	if not is_instance_valid(encounter):
		GLog.error("EffectProcessor: Cannot create context - invalid encounter")
		return null
	
	if not is_instance_valid(player_data):
		GLog.error("EffectProcessor: Cannot create context - invalid player_data")
		return null
	
	var context = EffectContext.new()
	
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
		GLog.debug("EffectProcessor: Created encounter context for %s" % _get_target_description(encounter))
	
	return context

## Create context for curio effects
func create_context_for_curio(curio: CurioData, trigger_event: String, game_state: Resource) -> EffectContext:
	if not is_instance_valid(curio):
		GLog.error("EffectProcessor: Cannot create context - invalid curio")
		return null
	
	if trigger_event.is_empty():
		GLog.error("EffectProcessor: Cannot create context - empty trigger_event")
		return null
	
	if not is_instance_valid(game_state):
		GLog.error("EffectProcessor: Cannot create context - invalid game_state")
		return null
	
	var context = EffectContext.new()
	
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
		GLog.warn("EffectProcessor: Unknown game_state type: %s" % game_state.get_class())
	
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
		GLog.debug("EffectProcessor: Created curio context for %s on %s" % [
			_get_target_description(curio),
			trigger_event
		])
	
	return context

## Validate batch processing inputs
func _validate_batch_inputs(effects: Array[GameEffect], context: EffectContext) -> bool:
	if effects.is_empty():
		GLog.warn("EffectProcessor: Empty effects array provided")
		return false
	
	if not is_instance_valid(context):
		GLog.error("EffectProcessor: Invalid context provided")
		return false
	
	if context.source_type.is_empty():
		GLog.error("EffectProcessor: Context missing source_type")
		return false
	
	# Validate each effect in the array
	for i in range(effects.size()):
		if not is_instance_valid(effects[i]):
			GLog.error("EffectProcessor: Invalid effect at index %d" % i)
			return false
		
		if not effects[i] is GameEffect:
			GLog.error("EffectProcessor: Non-GameEffect at index %d (type: %s)" % [i, effects[i].get_class()])
			return false
		
		if effects[i].effect_id.is_empty():
			GLog.warn("EffectProcessor: Effect at index %d has empty effect_id" % i)
	
	if DEBUG_ENABLED:
		GLog.debug("EffectProcessor: Batch validation passed for %d effects" % effects.size())
	
	return true

## Enable or disable context caching for performance optimization
func set_context_caching(enabled: bool) -> void:
	_cache_enabled = enabled
	if not enabled:
		_context_cache.clear()

## Clear the context cache
func clear_context_cache() -> void:
	_context_cache.clear()

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
		"history_entries": _processing_history.size()
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
		"effects_sorted_for_determinism": 0
	}
	
	if DEBUG_ENABLED:
		GLog.info("EffectProcessor: Statistics reset")

## Enable or disable debug tracing
func set_debug_trace_enabled(enabled: bool) -> void:
	_debug_trace_enabled = enabled
	if not enabled:
		_debug_trace_buffer.clear()
	
	if DEBUG_ENABLED:
		GLog.info("EffectProcessor: Debug tracing %s" % ("enabled" if enabled else "disabled"))

## Get debug trace buffer for analysis
func get_debug_trace() -> Array[Dictionary]:
	return _debug_trace_buffer.duplicate()

## Clear debug trace buffer
func clear_debug_trace() -> void:
	_debug_trace_buffer.clear()
	if DEBUG_ENABLED:
		GLog.debug("EffectProcessor: Debug trace buffer cleared")

## Get processing history for debugging
func get_processing_history() -> Array[Dictionary]:
	return _processing_history.duplicate()

## Clear processing history
func clear_processing_history() -> void:
	_processing_history.clear()
	if DEBUG_ENABLED:
		GLog.debug("EffectProcessor: Processing history cleared")

## Set performance monitoring thresholds
func set_performance_thresholds(thresholds: Dictionary) -> void:
	for key in thresholds.keys():
		if _performance_thresholds.has(key):
			_performance_thresholds[key] = thresholds[key]
	
	if DEBUG_ENABLED:
		GLog.info("EffectProcessor: Performance thresholds updated: %s" % _performance_thresholds)

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
		GLog.info("EffectProcessor: Debug report generated with %d trace entries and %d history entries" % [
			report.recent_trace.size(), report.recent_history.size()
		])
	
	return report

## Log detailed context information for debugging
func _log_context_details(context: EffectContext, operation: String) -> void:
	if not DEBUG_ENABLED or GLog.min_log_level > GLog.Level.TRACE:
		return
	
	GLog.trace("EffectProcessor: Context details for %s:" % operation)
	GLog.trace("  - Source: %s (%s)" % [context.source_type, _get_target_description(context.source_object)])
	GLog.trace("  - Target: %s" % _get_target_description(context.primary_target))
	GLog.trace("  - Trigger: %s" % context.trigger_event)
	
	if context.curio_modifications and not context.curio_modifications.is_empty():
		GLog.trace("  - Curio modifications: %d active" % context.curio_modifications.size())

## Log detailed effect context for debugging
func _log_detailed_effect_context(effect: GameEffect, context: EffectContext) -> void:
	GLog.trace("EffectProcessor: Detailed effect context:")
	GLog.trace("  - Effect ID: %s" % effect.effect_id)
	GLog.trace("  - Effect Type: %s" % effect.get_class())
	
	if effect.has_method("get_description"):
		GLog.trace("  - Description: %s" % effect.get_description())
	
	if context.trigger_data:
		GLog.trace("  - Trigger data keys: %s" % context.trigger_data.keys())

## Log effect result details for successful effects
func _log_effect_result_details(effect: GameEffect, result: EffectResult, _processing_time_ms: int) -> void:
	if not result.values_applied.is_empty():
		GLog.debug("EffectProcessor: Effect %s applied values: %s" % [effect.effect_id, result.values_applied])
	
	if not result.logs.is_empty():
		GLog.debug("EffectProcessor: Effect %s logs: %s" % [effect.effect_id, result.logs])

## Log effect failure details for debugging
func _log_effect_failure_details(effect: GameEffect, result: EffectResult, context: EffectContext, processing_time_ms: int) -> void:
	GLog.warn("EffectProcessor: Effect failure analysis for %s:" % effect.effect_id)
	GLog.warn("  - Processing time: %dms" % processing_time_ms)
	GLog.warn("  - Context source: %s" % context.source_type)
	GLog.warn("  - Target: %s" % _get_target_description(context.primary_target))
	
	if not result.logs.is_empty():
		GLog.warn("  - Error logs: %s" % result.logs)

## Log effect application failure details
func _log_effect_application_failure(effect: GameEffect, context: EffectContext) -> void:
	GLog.debug("EffectProcessor: Effect %s cannot be applied:" % effect.effect_id)
	GLog.debug("  - Source: %s" % context.source_type)
	GLog.debug("  - Target: %s" % _get_target_description(context.primary_target))
	GLog.debug("  - Trigger: %s" % context.trigger_event)

## Log effect application error details
func _log_effect_application_error(effect: GameEffect, result: EffectResult, apply_time_ms: int) -> void:
	GLog.warn("EffectProcessor: Effect %s application error (took %dms):" % [effect.effect_id, apply_time_ms])
	
	if not result.logs.is_empty():
		for log_entry in result.logs:
			GLog.warn("  - %s" % log_entry)

## Log successful effect details for trace level
func _log_successful_effect_details(effect: GameEffect, result: EffectResult, apply_time_ms: int) -> void:
	GLog.trace("EffectProcessor: Effect %s success details (took %dms):" % [effect.effect_id, apply_time_ms])
	
	if not result.values_applied.is_empty():
		for key in result.values_applied.keys():
			GLog.trace("  - %s: %s" % [key, result.values_applied[key]])

## Log batch performance summary
func _log_batch_performance_summary(effect_count: int, total_time_ms: int, processing_time_ms: int) -> void:
	var overhead_time = total_time_ms - processing_time_ms
	var overhead_percentage = (float(overhead_time) / float(total_time_ms)) * 100.0 if total_time_ms > 0 else 0.0
	
	GLog.debug("EffectProcessor: Batch performance summary:")
	GLog.debug("  - Effects: %d" % effect_count)
	GLog.debug("  - Total time: %dms" % total_time_ms)
	GLog.debug("  - Processing time: %dms" % processing_time_ms)
	GLog.debug("  - Overhead: %dms (%.1f%%)" % [overhead_time, overhead_percentage])
	GLog.debug("  - Avg per effect: %.1fms" % (float(processing_time_ms) / float(effect_count) if effect_count > 0 else 0.0))

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
func _validate_batch_inputs_enhanced(effects: Array[GameEffect], context: EffectContext) -> Dictionary:
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
		
		if not effect is GameEffect:
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
		GLog.debug("EffectProcessor: Enhanced batch validation passed for %d effects" % effects.size())
	
	result.valid = true
	return result

## Enhanced validation for single effect inputs
func _validate_single_effect_inputs(effect: GameEffect, context: EffectContext) -> Dictionary:
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
	
	if not effect is GameEffect:
		result.error_message = "Object is not a GameEffect (type: %s)" % effect.get_class()
		result.error_type = "wrong_effect_type"
		result.recoverable = false
		return result
	
	# Check context validity
	if not is_instance_valid(context):
		result.error_message = "Invalid effect context"
		result.error_type = "invalid_context"
		result.recoverable = false
		return result
	
	if not context is EffectContext:
		result.error_message = "Context is not an EffectContext (type: %s)" % context.get_class()
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
func _attempt_batch_recovery(effects: Array[GameEffect], context: EffectContext, validation_result: Dictionary) -> Dictionary:
	var recovery_result = {
		"success": false,
		"error_message": "",
		"recovery_action": "",
		"recovered_effects": effects,
		"recovered_context": context
	}
	
	match validation_result.error_type:
		"null_effects_array":
			recovery_result.recovered_effects = []
			recovery_result.success = true
			recovery_result.recovery_action = "Created empty effects array"
		
		"missing_source_type":
			context.source_type = "unknown"
			recovery_result.recovered_context = context
			recovery_result.success = true
			recovery_result.recovery_action = "Set default source_type to 'unknown'"
		
		"invalid_effects":
			if _malformed_data_recovery:
				var filtered_effects: Array[GameEffect] = []
				for i in range(effects.size()):
					var effect = effects[i]
					if is_instance_valid(effect) and effect is GameEffect:
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
func _attempt_effect_recovery(effect: GameEffect, context: EffectContext, validation_result: Dictionary) -> Dictionary:
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
func _validate_effect_for_processing(effect: GameEffect, index: int) -> bool:
	if not _null_safety_enabled:
		return true  # Skip validation if null safety is disabled
	
	if not is_instance_valid(effect):
		GLog.warn("EffectProcessor: Null effect at index %d, skipping" % index)
		_stats.null_safety_activations += 1
		return false
	
	if not effect is GameEffect:
		GLog.warn("EffectProcessor: Non-GameEffect at index %d (type: %s), skipping" % [index, effect.get_class()])
		_stats.null_safety_activations += 1
		return false
	
	if not effect.has_method("apply_effect") or not effect.has_method("can_apply"):
		GLog.warn("EffectProcessor: Effect at index %d missing required methods, skipping" % index)
		_stats.null_safety_activations += 1
		return false
	
	return true

## Validate an EffectResult for correctness
func _validate_effect_result(result: EffectResult) -> bool:
	if not is_instance_valid(result):
		return false
	
	if not result is EffectResult:
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

## Recover a malformed EffectResult
func _recover_malformed_result(malformed_result: EffectResult, effect: GameEffect) -> EffectResult:
	var recovered = EffectResult.new()
	
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
		recovered.logs = []
	
	# Add recovery log
	recovered.logs.append("Result recovered from malformed data for effect: %s" % _safe_get_effect_id(effect))
	
	return recovered

## Create a default EffectResult for recovery scenarios
func _create_default_effect_result(recovery_message: String) -> EffectResult:
	var result = EffectResult.new()
	result.success = false  # Default to failure for safety
	result.values_applied = {}
	result.logs = [recovery_message]
	return result

## Create a validation failure result
func _create_validation_failure_result(error_message: String) -> EffectResult:
	var result = EffectResult.new()
	result.success = false
	result.values_applied = {}
	result.logs = ["Validation failed: " + error_message]
	return result

## Safely get effect ID with null checking
func _safe_get_effect_id(effect: GameEffect) -> String:
	if not is_instance_valid(effect):
		return "null_effect"
	
	if not "effect_id" in effect:
		return "no_id_property"
	
	if effect.effect_id.is_empty():
		return "empty_id"
	
	return effect.effect_id

## Extract failure reason from EffectResult
func _extract_failure_reason(result: EffectResult) -> String:
	if not result or not result.logs or result.logs.is_empty():
		return "Unknown failure reason"
	
	return result.logs[0]

## Determine if a failure is critical
func _is_critical_failure(result: EffectResult) -> bool:
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
	
	GLog.error("EffectProcessor: Critical error - %s: %s" % [error_type, str(error_details)])
	
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
	
	GLog.warn("EffectProcessor: Validation error - %s: %s" % [validation_type, error_message])
	
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
		GLog.info("EffectProcessor: Error handling configuration updated: %s" % str(config))

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
		GLog.info("EffectProcessor: Error handling state reset")

## Legacy compatibility method for migration
## Processes card effects and returns results in the legacy dictionary format
func apply_card_instance_effects(duel_manager: DuelManager, card_instance: CardInstance) -> Dictionary:
	return apply_card_instance_effects_with_context(duel_manager, card_instance, 0, 0)

## Legacy compatibility method with context for migration
func apply_card_instance_effects_with_context(duel_manager: DuelManager, card_instance: CardInstance, cards_played_before: int, hand_size_before: int) -> Dictionary:
	# Create default results dictionary for backward compatibility
	var results = _create_legacy_results_dict()
	
	# Validate inputs
	if not is_instance_valid(duel_manager) or not is_instance_valid(card_instance):
		GLog.error("EffectProcessor: Invalid inputs for card effect processing")
		return results
	
	if not card_instance.card_data or not card_instance.card_data.effects:
		return results
	
	# Create context
	var context = create_context_for_card(card_instance, duel_manager)
	
	# Add timing information to context
	context.trigger_data["cards_played_this_turn"] = cards_played_before
	context.trigger_data["hand_size"] = hand_size_before
	
	# Process effects
	var typed_effects: Array[GameEffect] = []
	for effect in card_instance.card_data.effects:
		if effect is GameEffect:
			typed_effects.append(effect)
		else:
			GLog.warn("EffectProcessor: Skipping non-GameEffect in card effects: %s" % effect)
	
	var effect_results = process_effects(typed_effects, context)
	
	# Convert modern EffectResult array to legacy dictionary format
	_merge_results_to_legacy_dict(effect_results, results)
	
	# Apply gambling modifiers if applicable (legacy compatibility)
	_apply_gambling_modifiers(duel_manager, results)
	
	return results

## Create legacy results dictionary for backward compatibility
func _create_legacy_results_dict() -> Dictionary:
	return {
		"damage": 0,
		"defense": 0,
		"heal": 0,
		"draw": 0,
		"energy_restore": 0,
		"stun_enemy": 0,
		"ignores_defense": false,
		"discard_random": 0,
		"add_curse": 0,
		"sanity_restore": 0,
		"exhaust_random": 0
	}

## Merge modern EffectResult array into legacy dictionary format
func _merge_results_to_legacy_dict(effect_results: Array[EffectResult], results: Dictionary) -> void:
	for effect_result in effect_results:
		if not effect_result.success:
			continue
		
		var values = effect_result.values_applied
		if not values is Dictionary:
			continue
		
		# Map modern result values to legacy dictionary keys
		for key in values.keys():
			match key:
				"damage":
					if values[key] > 0:
						results.damage += values[key]
				"heal":
					if values[key] > 0:
						results.heal += values[key]
				"defense":
					if values[key] > 0:
						results.defense += values[key]
				"drawn":
					if values[key] > 0:
						results.draw += values[key]
				"discard_random":
					if values[key] > 0:
						results.discard_random += values[key]
				"exhaust_random":
					if values[key] > 0:
						results.exhaust_random += values[key]
				"ignores_defense":
					if values[key]:
						results.ignores_defense = true
				"stun_enemy":
					if values[key] > 0:
						results.stun_enemy += values[key]
				"energy":
					if values[key] != 0:
						results.energy_restore += values[key]
				"sanity":
					if values[key] > 0:
						results.sanity_restore += values[key]
				# Add other mappings as needed

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
			GLog.debug("EffectProcessor: Gambling active! Multiplier: %.1fx" % multiplier)
		
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
				GLog.debug("EffectProcessor: Gambling SUCCESS! Effects multiplied by %.1fx" % multiplier)
		else:
			# Negate effects on gambling failure
			results.damage = 0
			results.defense = 0
			results.heal = 0
			
			if DEBUG_ENABLED:
				GLog.debug("EffectProcessor: Gambling FAILED! All effects negated")

## Sort effects for deterministic processing
func _sort_effects_for_deterministic_processing(effects: Array[GameEffect]) -> Array[GameEffect]:
	"""Sort effects by their effect_id to ensure consistent processing order.
	
	This ensures that identical effect arrays are always processed in the same order,
	which is crucial for deterministic behavior.
	
	Args:
		effects: Array of GameEffect instances to sort
		
	Returns:
		New array with effects sorted by effect_id
	"""
	if not _deterministic_mode or effects.size() <= 1:
		return effects
	
	# Create a copy to avoid modifying the original array
	var sorted_effects = effects.duplicate()
	
	# Sort by effect_id using a stable sort
	sorted_effects.sort_custom(func(a: GameEffect, b: GameEffect) -> bool:
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
func validate_deterministic_processing(effects: Array[GameEffect], context: EffectContext, iterations: int = 3) -> Dictionary:
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
			GLog.debug("EffectProcessor: Deterministic validation PASSED for %d effects over %d iterations" % [effects.size(), iterations])
		else:
			GLog.warn("EffectProcessor: Deterministic validation FAILED - found %d differences" % validation_result.differences.size())
			for diff in validation_result.differences:
				GLog.warn("  - %s" % diff)
	
	return validation_result

## Serialize results for comparison in deterministic validation
func _serialize_results_for_comparison(results: Array[EffectResult]) -> Array[Dictionary]:
	"""Convert EffectResult array to comparable format for deterministic validation."""
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
		GLog.info("EffectProcessor: Deterministic processing configured: %s" % str(config))

## Get current deterministic processing configuration
func get_deterministic_processing_config() -> Dictionary:
	"""Get current deterministic processing configuration."""
	return {
		"deterministic_mode": _deterministic_mode,
		"sort_effects_by_id": _sort_effects_by_id,
		"validate_deterministic_results": _validate_deterministic_results
	}