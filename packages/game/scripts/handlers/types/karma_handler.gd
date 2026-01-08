extends "res://scripts/handlers/core/handler_base.gd"
class_name KarmaHandler

@export var karma_category: String = "wildlife"
@export var amount: int = 1
@export var reason: String = ""
@export var narrative_description: String = ""

## Applies karma changes to the player in a specific category (wildlife, people, etc.).
## Returns a HandlerResult with karma delta to be tracked for moral alignment.
func apply_effect(context: Resource) -> Resource:
    var result = HandlerResult.new()
    var player = context.player_data if context else null
    if player == null or not player.has_method("add_karma"):
        result.success = false
        result.prevented_by = "no_player"
        return result
    player.add_karma(karma_category, amount, reason)
    # Emit karma change via EventBus if available
    if context and context.game_manager:
        var eb = context.game_manager.get_node_or_null("/root/EventBus")
        if eb and player.has_method("get_karma") and player.has_method("get_moral_karma"):
            eb.emit_signal("karma_changed", karma_category, player.get_karma(karma_category), player.get_moral_karma())
    result.values_applied["karma"] = amount
    result.success = true
    result.ui_feedback = {"message": ("%s%d %s karma" % [("+" if amount > 0 else ""), amount, karma_category.capitalize()])}
    return result

func get_description_text(_context: Resource = null) -> String:
    var sign_prefix = "+" if amount > 0 else ""
    return "%s%d %s karma" % [sign_prefix, amount, karma_category.capitalize()]
