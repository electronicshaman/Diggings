extends RefCounted
class_name LineSegment

const DEBUG_ENABLED: bool = false

# Line segment defined by two points
var p1: Vector2
var p2: Vector2

func _init(point1: Vector2, point2: Vector2):
	p1 = point1
	p2 = point2

# Check if this line segment intersects with another line segment
func intersects_with(other: LineSegment) -> bool:
	return segments_intersect(p1, p2, other.p1, other.p2)

# Get the intersection point if segments intersect
func get_intersection_point(other: LineSegment) -> Vector2:
	var result = segments_intersection_point(p1, p2, other.p1, other.p2)
	return result if result != Vector2.INF else Vector2.ZERO

# Static method to check if two line segments intersect
static func segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	# Check if segments share an endpoint (not considered intersection)
	if a1 == b1 or a1 == b2 or a2 == b1 or a2 == b2:
		return false
	
	# Use orientation method for robust intersection detection
	var o1 = orientation(a1, a2, b1)
	var o2 = orientation(a1, a2, b2)
	var o3 = orientation(b1, b2, a1)
	var o4 = orientation(b1, b2, a2)
	
	# General case: segments intersect if orientations are different
	if o1 != o2 and o3 != o4:
		return true
	
	# Special cases where points are collinear
	if o1 == 0 and point_on_segment(a1, b1, a2):
		return true
	if o2 == 0 and point_on_segment(a1, b2, a2):
		return true  
	if o3 == 0 and point_on_segment(b1, a1, b2):
		return true
	if o4 == 0 and point_on_segment(b1, a2, b2):
		return true
	
	return false

# Get intersection point of two line segments (returns Vector2.INF if no intersection)
static func segments_intersection_point(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> Vector2:
	if not segments_intersect(a1, a2, b1, b2):
		return Vector2.INF
	
	# Calculate intersection using parametric form
	var d1 = a2 - a1
	var d2 = b2 - b1
	var d3 = a1 - b1
	
	var cross_d1_d2 = d1.x * d2.y - d1.y * d2.x
	
	# Lines are parallel
	if abs(cross_d1_d2) < 1e-10:
		return Vector2.INF
	
	var t1 = (d3.x * d2.y - d3.y * d2.x) / cross_d1_d2
	
	return a1 + t1 * d1

# Calculate orientation of ordered triplet of points
# Returns: 0 = collinear, 1 = clockwise, 2 = counterclockwise
static func orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	
	if abs(val) < 1e-10:  # Use epsilon for floating point comparison
		return 0  # Collinear
	
	return 1 if val > 0 else 2  # Clockwise or counterclockwise

# Check if point q lies on line segment pr (only call if points are collinear)
static func point_on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and \
		   q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y)

# Get the length of this line segment
func length() -> float:
	return p1.distance_to(p2)

# Get the direction vector (normalized)
func direction() -> Vector2:
	return (p2 - p1).normalized()

# Get the midpoint of the segment
func midpoint() -> Vector2:
	return (p1 + p2) * 0.5

# Check if a point is within a given distance of this line segment
func point_distance_to_segment(point: Vector2) -> float:
	var segment_length_sq = p1.distance_squared_to(p2)
	
	# If the segment has zero length, return distance to p1
	if segment_length_sq < 1e-10:
		return point.distance_to(p1)
	
	# Calculate the t parameter for the projection of point onto the segment
	var t = max(0.0, min(1.0, (point - p1).dot(p2 - p1) / segment_length_sq))
	
	# Find the projection point
	var projection = p1 + t * (p2 - p1)
	
	return point.distance_to(projection)

# Convert to string for debugging
func _to_string() -> String:
	return "LineSegment(" + str(p1) + " -> " + str(p2) + ")"