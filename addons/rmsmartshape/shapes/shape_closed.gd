@tool
@icon("../assets/closed_shape.png")
extends SS2D_Shape
class_name SS2D_Shape_Closed
## DEPRECATED: Use [SS2D_Shape] instead.
## @deprecated

# UNUSED FUNCTIONS:

## Returns true if line segment 'a1a2' and 'b1b2' intersect.[br]
## Find the four orientations needed for general and special cases.[br]
#func do_edges_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
#	var o1: int = get_points_orientation([a1, a2, b1])
#	var o2: int = get_points_orientation([a1, a2, b2])
#	var o3: int = get_points_orientation([b1, b2, a1])
#	var o4: int = get_points_orientation([b1, b2, a2])
#
#	# General case
#	if o1 != o2 and o3 != o4:
#		return true
#
#	# Special Cases
#	# a1, a2 and b1 are colinear and b1 lies on segment p1q1
#	if o1 == ORIENTATION.COLINEAR and on_segment(a1, b1, a2):
#		return true
#
#	# a1, a2 and b2 are colinear and b2 lies on segment p1q1
#	if o2 == ORIENTATION.COLINEAR and on_segment(a1, b2, a2):
#		return true
#
#	# b1, b2 and a1 are colinear and a1 lies on segment p2q2
#	if o3 == ORIENTATION.COLINEAR and on_segment(b1, a1, b2):
#		return true
#
#	# b1, b2 and a2 are colinear and a2 lies on segment p2q2
#	if o4 == ORIENTATION.COLINEAR and on_segment(b1, a2, b2):
#		return true
#
#	# Doesn't fall in any of the above cases
#	return false


#static func get_edge_intersection(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> Variant:
#	var den: float = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y)
#
#	# Check if lines are parallel or coincident
#	if den == 0:
#		return null
#
#	var ua: float = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / den
#	var ub: float = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / den
#
#	if ua < 0 or ub < 0 or ua > 1 or ub > 1:
#		return null
#
#	return Vector2(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y))


