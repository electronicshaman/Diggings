extends Resource
class_name MapConfig

# Total nodes
@export_range(15, 40, 1) var total_nodes: int = 25

# Node type distribution (min/max for each type)
@export_group("Node Distribution")
@export_range(1, 1, 1) var city_count: int = 1  # Always exactly 1
@export_range(2, 6, 1) var min_settlements: int = 3
@export_range(2, 6, 1) var max_settlements: int = 4
@export_range(4, 10, 1) var min_camps: int = 6
@export_range(4, 10, 1) var max_camps: int = 8
@export_range(2, 8, 1) var min_mines: int = 4
@export_range(2, 8, 1) var max_mines: int = 6
@export_range(1, 5, 1) var min_pois: int = 2
@export_range(1, 5, 1) var max_pois: int = 4
@export_range(2, 8, 1) var min_junctions: int = 3
@export_range(2, 8, 1) var max_junctions: int = 5
@export_range(0, 2, 1) var min_bosses: int = 0
@export_range(0, 2, 1) var max_bosses: int = 1

# Visual settings
@export_group("Visual")
@export var edge_color: Color = Color.WHITE
@export_range(2.0, 10.0, 0.5) var edge_width: float = 4.0
@export_range(-10, 10, 1) var edge_z_index: int = 1
@export_range(-10, 10, 1) var node_z_index: int = 2

# Edge filtering
@export_group("Edge Filtering")
@export_range(100.0, 500.0, 10.0) var max_edge_length: float = 300.0
@export_range(1, 6, 1) var min_edges_per_node: int = 2

# Debug options
@export_group("Debug")
@export var show_outcome_debug_badges: bool = false