# GLog Usage Guide

Custom logging system for clean, toggleable debugging in your card battler prototype.

## Quick Start

### 1. Super Simple Usage (Recommended!)
```gdscript
# At the top of any file
const DEBUG_ENABLED: bool = true

# In your functions - that's it!
GLog.debug("Your debug message")
GLog.warn("Something suspicious")
GLog.error("Something went wrong")
```

### 2. Advanced Usage
```gdscript
# Different log levels - all automatically check DEBUG_ENABLED
GLog.trace("Very detailed info")      # Lowest priority
GLog.debug("General debugging")       # Development info
GLog.info("Important events")         # General information  
GLog.warn("Something suspicious")     # Warning messages
GLog.error("Something went wrong")    # Error messages
GLog.critical("System is broken")     # Highest priority

# Method entry/exit tracing
GLog.log_method_enter("my_function", [param1, param2])
GLog.log_method_exit("my_function", return_value)
```

## File-Level Debug Control

### Pattern 1: Const Toggle (Automatic!)
```gdscript
extends Node
class_name MyClass

# Set to false to completely disable logging from this file
const DEBUG_ENABLED: bool = true

func my_function():
    # GLog automatically checks DEBUG_ENABLED - no if statement needed!
    GLog.debug("This message only appears if DEBUG_ENABLED is true")
    GLog.warn("This warning also respects DEBUG_ENABLED")
```

### Pattern 2: Runtime Toggle (Dynamic)
```gdscript
extends Node

func _ready():
    # Enable/disable logging for specific files at runtime
    GLog.set_file_debug("CardPile", false)  # Disable CardPile logging
    GLog.set_file_debug("DuelManager", true) # Enable DuelManager logging
    
func my_function():
    # This respects the runtime toggle
    GLog.debug("This message", "MyClass")
```

## Global Control

```gdscript
# Turn off ALL logging globally
GLog.disable_debug()

# Turn on ALL logging globally  
GLog.enable_debug()

# Set minimum log level (ignores logs below this level)
GLog.set_min_level(GLog.Level.WARN)  # Only show WARN, ERROR, CRITICAL
```

## Real Examples from CardPile

```gdscript
extends Resource
class_name CardPile

# File-level debug toggle
const DEBUG_ENABLED: bool = true

func _init(type: String = "generic", maximum_size: int = -1):
    # Simple debug with source file name
    if DEBUG_ENABLED:
        GLog.debug("CardPile created: type=%s, max_size=%s" % [type, maximum_size], "CardPile")

func add_card(card_data: CardData) -> bool:
    if not card_data:
        # Warning for suspicious behavior
        if DEBUG_ENABLED:
            GLog.warn("Attempted to add null card to %s pile" % pile_type, "CardPile")
        return false
    
    # Normal operation logging
    if DEBUG_ENABLED:
        GLog.debug("Added card: %s (pile size: %d)" % [card_data.card_name, cards.size()], "CardPile")
```

## Log Output Format

```
[14:32:45] [DEBUG] [CardPile] Added card to hand pile: Pickaxe Strike (pile size: 3)
[14:32:46] [WARN] [DuelManager] Player has no energy left
[14:32:47] [ERROR] [CardEffects] Effect failed to apply: invalid target
```

## Performance Tips

1. **Use const DEBUG_ENABLED** for zero runtime cost when disabled
2. **Check DEBUG_ENABLED first** to avoid string formatting when disabled
3. **Use appropriate log levels** to filter noise
4. **Include useful context** in messages (card names, counts, states)

## Common Patterns

### For Critical Systems (Always Log Errors)
```gdscript
const DEBUG_ENABLED: bool = true

func critical_function():
    if not validate_state():
        # Always log errors/warnings even if debug disabled
        GLog.error("Critical validation failed", "SystemName")
        return false
    
    # Optional debug info
    if DEBUG_ENABLED:
        GLog.debug("Validation passed", "SystemName")
```

### For Noisy Systems (Easy to Disable)
```gdscript
const DEBUG_ENABLED: bool = false  # Set to false to silence

func frequently_called_function():
    if DEBUG_ENABLED:
        GLog.trace("Processing frame data", "AnimationSystem")
```

### For Testing New Features
```gdscript
const DEBUG_ENABLED: bool = true  # Enable while developing

func new_experimental_feature():
    if DEBUG_ENABLED:
        GLog.debug("Starting experimental feature", "NewFeature")
        GLog.log_method_enter("new_experimental_feature")
    
    # ... your code ...
    
    if DEBUG_ENABLED:
        GLog.log_method_exit("new_experimental_feature")
```

## Quick Reference

- `GLog.debug()` - General development info
- `GLog.info()` - Important events  
- `GLog.warn()` - Suspicious behavior
- `GLog.error()` - Things that went wrong
- `GLog.set_file_debug("FileName", false)` - Disable specific file
- `GLog.disable_debug()` - Disable all logging
- `const DEBUG_ENABLED: bool = false` - Compile-time disable per file