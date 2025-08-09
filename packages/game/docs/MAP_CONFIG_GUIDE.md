# Map Configuration System Guide

## Overview

The map generation system uses a configurable resource-based approach that allows easy tweaking of map layout parameters without code changes. This guide explains how to use the MapLayoutConfig system to refine map generation.

## Quick Start

1. **Open the config file**: `res://data/map_layout_config.tres` in Godot's Inspector
2. **Modify parameters**: Adjust values in real-time
3. **Test changes**: Use the map scene's `regenerate_map()` method or restart the map scene
4. **Hot reload**: Call `reload_config()` on the Map controller for instant updates

## Configuration File Location

- **Main config**: `res://data/map_layout_config.tres`
- **Script source**: `scripts/map/MapLayoutConfig.gd`

## Parameter Categories

### 🗺️ Map Size & Node Counts

```gdscript
@export_range(10, 50, 1) var min_nodes: int = 20          # Minimum nodes to generate
@export_range(15, 100, 1) var max_nodes: int = 30         # Maximum nodes to generate
```

**Effect**: Controls total map size. More nodes = larger, more complex maps.

### 🔗 Connection Distances

```gdscript
@export_range(50, 500, 10) var connection_max_distance: float = 250.0    # Max connection length
@export_range(20, 200, 5) var connection_min_distance: float = 60.0      # Min connection length
```

**Effect**: Prevents messy long connections across the map. Key for fixing edge quality issues.

### 📐 Node Spacing

```gdscript
@export_range(80, 300, 10) var spacing_min: float = 100.0     # Minimum distance between nodes
@export_range(120, 400, 10) var spacing_max: float = 200.0    # Maximum distance between nodes
```

**Effect**: Controls how spread out nodes are. Larger spacing = less cluttered maps.

### ⚖️ Generation Rule Weights

Controls how often different generation patterns are applied:

```gdscript
@export_range(0.1, 10.0, 0.1) var linear_weight: float = 3.0        # Linear path probability
@export_range(0.1, 10.0, 0.1) var branch_weight: float = 2.0        # Branch creation probability  
@export_range(0.1, 10.0, 0.1) var destination_weight: float = 1.5   # Destination placement probability
```

**Effect**: Higher weights = more frequent application of that rule type.

### 🎯 Rule Application Limits

```gdscript
@export_range(5, 50, 1) var linear_max_applications: int = 20      # Max linear extensions
@export_range(3, 20, 1) var branch_max_applications: int = 10      # Max branch creations
@export_range(2, 15, 1) var destination_max_applications: int = 8  # Max destination placements
```

### 🏛️ Node Type Distribution

```gdscript
@export_range(0.0, 1.0, 0.05) var camp_weight: float = 0.2        # Rest/healing locations
@export_range(0.0, 1.0, 0.05) var mine_weight: float = 0.3        # Combat/resource locations  
@export_range(0.0, 1.0, 0.05) var settlement_weight: float = 0.25  # Shop/NPC locations
@export_range(0.0, 1.0, 0.05) var poi_weight: float = 0.25        # Event/mystery locations
```

**Effect**: Controls what types of locations appear on the map.

### 🔧 Advanced Parameters

- **Movement patterns**: `movement_angle_bias`, `movement_variance`  
- **Generation bounds**: `generation_bounds` (viewport constraints)
- **Connection cleanup**: `cleanup_remove_long_connections`
- **Difficulty scaling**: `branch_difficulty_bonus`

## Common Configuration Scenarios

### 📏 Linear Path Map
```gdscript
linear_weight = 5.0
branch_weight = 1.0  
destination_weight = 2.0
max_nodes = 20
```

### 🌳 Branching Tree Map
```gdscript  
linear_weight = 2.0
branch_weight = 4.0
destination_weight = 1.5
branch_max_applications = 15
```

### 🏘️ Clustered Regions Map
```gdscript
spacing_min = 80.0
spacing_max = 150.0
connection_max_distance = 180.0
settlement_weight = 0.4
```

### 🏔️ Sparse Exploration Map
```gdscript
max_nodes = 40
spacing_min = 150.0
spacing_max = 250.0
connection_max_distance = 300.0
```

## Graph Rewriting Concepts

The map generator uses **graph rewriting rules** - pattern-matching algorithms that transform the map structure:

### Linear Extension Rule
- **Pattern**: Finds nodes with ≤2 connections
- **Action**: Extends a linear path: `Node → Junction → Destination`
- **Use**: Creates main progression paths

### Branch Creation Rule  
- **Pattern**: Finds junctions with <3 connections
- **Action**: Adds side branches: `Junction → Branch Destination`
- **Use**: Creates optional exploration areas

### Destination Placement Rule
- **Pattern**: Finds junctions with ≥1 connection  
- **Action**: Converts junction to meaningful location type
- **Use**: Ensures interesting destinations exist

## Testing & Iteration

### In-Editor Testing
1. Open `res://scenes/game/map.tscn`
2. Modify config values in Inspector
3. Run scene to see changes
4. Use Map controller's debug methods

### Runtime Hot Reloading
```gdscript
# In Map scene
map_controller.reload_config()    # Reload config from file
map_controller.regenerate_map()   # Generate new map with current config
```

### Debugging Tools
- Enable `debug_show_all_nodes` to see full map
- Check GLog output for generation statistics
- Use MapVisualizer's `debug_state()` for diagnostics

## Validation & Warnings

The config system includes automatic validation:

```gdscript
var warnings = config.validate_config()
# Warns about: invalid ranges, conflicting settings, performance issues
```

Common warnings:
- **High node counts** with small bounds (overcrowding)
- **Very short** max connection distances (disconnected map)
- **Zero rule weights** (generation fails)

## File Structure

```
├── scripts/map/
│   ├── MapLayoutConfig.gd          # Configuration class definition
│   ├── MapGenerator.gd             # Uses config for generation  
│   └── GraphRule.gd                # Rules use config parameters
├── data/
│   └── map_layout_config.tres      # Your editable configuration
└── docs/
    └── MAP_CONFIG_GUIDE.md         # This guide
```

## Integration Points

The config system integrates with:

- **MapGenerator**: Core generation logic
- **GraphRule classes**: Pattern matching and node creation
- **MapVisualizer**: Display and bounds calculation  
- **Map scene**: Hot reloading and testing interface

## Best Practices

1. **Start with defaults** and make incremental changes
2. **Test frequently** - small parameter changes can have big effects
3. **Use validation warnings** to catch problematic configurations
4. **Document your presets** for different map styles
5. **Consider performance** - very large maps may impact gameplay

## Troubleshooting

### Map Generation Fails
- Check that rule weights are > 0
- Ensure max_nodes > min_nodes  
- Verify generation bounds are reasonable

### Disconnected/Isolated Nodes
- Increase `connection_max_distance`
- Enable `cleanup_remove_long_connections = false`
- Check spacing parameters aren't too large

### Messy Edge Connections  
- Decrease `connection_max_distance`
- Increase `connection_min_distance`
- Adjust `spacing_min` for better node distribution

### Poor Node Type Balance
- Adjust node type weights (should sum to ~1.0)
- Check rule application limits
- Verify destination placement rules are running

---

*This configuration system gives you full control over map generation without touching code. Experiment with different parameter combinations to create the perfect map layouts for your game!*