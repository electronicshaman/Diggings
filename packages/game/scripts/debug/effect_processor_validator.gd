extends Node

const DEBUG_ENABLED: bool = true

## Simple validator to test EffectProcessor functionality
## This script can be attached to a node in a test scene

func _ready():
	if DEBUG_ENABLED:
		GLog.info("EffectProcessorValidator: Starting validation")
		await get_tree().create_timer(0.1).timeout
		_run_validation()

func _run_validation():
	# Load the EffectProcessor script directly
	var EffectProcessorScript = load("res://scripts/systems/effect_processor.gd")
	if not EffectProcessorScript:
		GLog.error("EffectProcessorValidator: Could not load EffectProcessor script")
		return
	
	# Create an instance
	var processor = EffectProcessorScript.new()
	if not processor:
		GLog.error("EffectProcessorValidator: Could not create EffectProcessor instance")
		return
	
	GLog.info("EffectProcessorValidator: EffectProcessor created successfully")
	
	# Test basic functionality
	var diagnostics = processor.get_processing_diagnostics()
	GLog.info("EffectProcessorValidator: Diagnostics: %s" % str(diagnostics))
	
	# Test context creation with null inputs (should handle gracefully)
	var context = processor.create_context_for_card(null, null)
	if context == null:
		GLog.info("EffectProcessorValidator: Null input handling works correctly")
	else:
		GLog.warn("EffectProcessorValidator: Expected null context for null inputs")
	
	# Test statistics
	processor.reset_statistics()
	var stats = processor.get_processing_diagnostics()
	if stats.has("statistics"):
		GLog.info("EffectProcessorValidator: Statistics system working")
	
	GLog.info("EffectProcessorValidator: Basic validation completed successfully")
	processor.queue_free()