extends Resource
class_name SanityThresholdTracker

## Tracks sanity tier transitions and triggers threshold-based effects.
## Inspired by Call of Cthulhu's graduated insanity system.
## Part of the sanity mechanic improvements to make sanity more impactful.

# Signals for tier changes and corruption events
signal tier_changed(old_tier: int, new_tier: int)
signal corruption_triggered(tier: int, card_path: String)
signal sanity_crisis(tier: int, loss_amount: int)

## Corruption cards to inject at each tier threshold (path -> CardData)
## These represent the mental toll of descending into madness.
const CORRUPTION_CARDS = {
	# SHAKEN (50-75%): Minor corruption, temporary panic
	Stats.SanityTier.SHAKEN: "res://data/cards/curse/spiraling_thoughts.tres",
	# UNSTABLE (25-50%): Significant corruption, persistent dread
	Stats.SanityTier.UNSTABLE: "res://data/cards/curse/creeping_dread.tres",
	# BROKEN (<=25%): Severe corruption, mental fragmentation
	Stats.SanityTier.BROKEN: "res://data/cards/curse/shattered_mind.tres"
}

## Track the last known tier
var _last_tier: Stats.SanityTier = Stats.SanityTier.STABLE

## Track which tiers have already triggered corruption (once per run)
var _corruption_triggered_for_tiers: Dictionary = {}

## Track sanity at start of current "event" for crisis detection
var _sanity_before_event: int = -1


## Check if sanity tier has changed and trigger appropriate effects.
## Call this after any sanity-changing event.
func check_threshold(player_data) -> void:
	if not player_data or not player_data.stats:
		return
	
	var current_tier: Stats.SanityTier = player_data.stats.get_sanity_tier()
	
	if current_tier != _last_tier:
		var old_tier = _last_tier
		_last_tier = current_tier
		
		# Emit tier change signal
		tier_changed.emit(old_tier, current_tier)
		
		# Only trigger corruption on descent (tier number increases = worse)
		if current_tier > old_tier:
			_trigger_corruption_for_tier(current_tier)
		
		GLog.info("Sanity tier changed: %s -> %s" % [
			Stats.get_tier_name(old_tier),
			Stats.get_tier_name(current_tier)
		])


## Begin tracking for a sanity-affecting event (attack, card cost, etc.)
## Call this before sanity changes to enable crisis detection.
func begin_sanity_event(player_data) -> void:
	if player_data and player_data.stats:
		_sanity_before_event = player_data.stats.current_sanity


## End tracking for a sanity event and check for crisis.
## A "crisis" is losing a large amount of sanity in a single event.
func end_sanity_event(player_data) -> void:
	if not player_data or not player_data.stats or _sanity_before_event < 0:
		_sanity_before_event = -1
		return
	
	var current_sanity = player_data.stats.current_sanity
	var loss_amount = _sanity_before_event - current_sanity
	
	# Sanity crisis: losing 5+ sanity in a single event (25% of base 20)
	# This mirrors CoC's "5+ SAN loss triggers INT roll" mechanic
	if loss_amount >= 5:
		var current_tier = player_data.stats.get_sanity_tier()
		sanity_crisis.emit(current_tier, loss_amount)
		GLog.warn("Sanity crisis! Lost %d sanity in one event." % loss_amount)
	
	# Always check thresholds after sanity changes
	check_threshold(player_data)
	
	_sanity_before_event = -1


## Trigger corruption card injection for a specific tier.
func _trigger_corruption_for_tier(tier: Stats.SanityTier) -> void:
	# Only trigger corruption once per tier per run
	if _corruption_triggered_for_tiers.get(tier, false):
		return
	
	_corruption_triggered_for_tiers[tier] = true
	
	var card_path = CORRUPTION_CARDS.get(tier, "")
	if card_path.is_empty():
		return
	
	# Emit signal so DeckManager or other systems can add the card
	corruption_triggered.emit(tier, card_path)
	
	GLog.info("Corruption triggered at tier %s: %s" % [
		Stats.get_tier_name(tier),
		card_path.get_file()
	])


## Reset tracker for a new run.
func reset() -> void:
	_last_tier = Stats.SanityTier.STABLE
	_corruption_triggered_for_tiers.clear()
	_sanity_before_event = -1


## Get current tier being tracked.
func get_current_tier() -> Stats.SanityTier:
	return _last_tier


## Check if corruption has been triggered for a specific tier.
func has_triggered_corruption(tier: Stats.SanityTier) -> bool:
	return _corruption_triggered_for_tiers.get(tier, false)


## Force-sync the tracker to player's current state.
## Use this when loading a save or starting a run.
func sync_to_player(player_data) -> void:
	if player_data and player_data.stats:
		_last_tier = player_data.stats.get_sanity_tier()
	else:
		_last_tier = Stats.SanityTier.STABLE
