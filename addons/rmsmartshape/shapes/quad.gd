@tool
extends RefCounted
class_name SS2D_Quad

enum ORIENTATION { COLINEAR = 0, CCW, CW }
enum CORNER { NONE = 0, OUTER, INNER }

var pt_a: Vector2
var pt_b: Vector2
var pt_c: Vector2
var pt_d: Vector2

var tg_a : Vector2
var tg_b : Vector2
var tg_c : Vector2
var tg_d : Vector2

var bn_a : Vector2
var bn_b : Vector2
var bn_c : Vector2
var bn_d : Vector2

var texture: Texture2D = null
var color: Color = Color(1.0, 1.0, 1.0, 1.0)

var flip_texture: bool = false
# Deprecated, should remove control_point_index
var control_point_index: int
var fit_texture := SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH

# Contains value from CORNER enum
var corner: int = 0


# Will return two quads split down the middle of this one
func bisect() -> Array[SS2D_Quad]:
	var delta: Vector2 = pt_d - pt_a
	var delta_normal := delta.normalized()
	var quad_left: SS2D_Quad = duplicate()
	var quad_right: SS2D_Quad = duplicate()
	var mid_point := Vector2(get_length_average(), 0.0) * delta_normal
	quad_left.pt_d = pt_a + mid_point
	quad_left.pt_c = pt_b + mid_point
	quad_right.pt_a = pt_d - mid_point
	quad_right.pt_b = pt_c - mid_point
	return [quad_left, quad_right]


func _to_string() -> String:
	return "[Quad] A:%s B:%s C:%s D:%s | Corner: %s" % [pt_a, pt_b, pt_c, pt_d, corner]


func matches_quad(q: SS2D_Quad) -> bool:
	return (
		texture == q.texture
		and color == q.color
		and flip_texture == q.flip_texture
		and fit_texture == q.fit_texture
	)


func duplicate() -> SS2D_Quad:
	var q := SS2D_Quad.new()
	q.pt_a = pt_a
	q.pt_b = pt_b
	q.pt_c = pt_c
	q.pt_d = pt_d

	q.texture = texture
	q.color = color

	q.flip_texture = flip_texture
	q.control_point_index = control_point_index

	q.corner = corner
	return q


func update_tangents() -> void:
	tg_a = (pt_d-pt_a).normalized()
	tg_b = (pt_c-pt_b).normalized()
	tg_c = tg_b
	tg_d = tg_a

	bn_a = (pt_b - pt_a).normalized()
	bn_b = bn_a
	bn_c = (pt_c - pt_d).normalized()
	bn_d = bn_c


func _init(
	a: Vector2 = Vector2.ZERO,
	b: Vector2 = Vector2.ZERO,
	c: Vector2 = Vector2.ZERO,
	d: Vector2 = Vector2.ZERO,
	t: Texture2D = null,
	f: bool = false
) -> void:
	pt_a = a
	pt_b = b
	pt_c = c
	pt_d = d

	texture = t
	flip_texture = f


func get_rotation() -> float:
	return SS2D_NormalRange.get_angle_from_vector(pt_c - pt_a)


## Given three colinear points p, q, r, the function checks if
## point q lies on line segment 'pr'.
func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (
		(q.x <= maxf(p.x, r.x))
		and (q.x >= minf(p.x, r.x))
		and (q.y <= maxf(p.y, r.y))
		and (q.y >= minf(p.y, r.y))
	)


## Returns CCW, CW, or colinear.[br]
## see https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
func get_orientation(a: Vector2, b: Vector2, c: Vector2) -> ORIENTATION:
	var val := (float(b.y - a.y) * (c.x - b.x)) - (float(b.x - a.x) * (c.y - b.y))
	if val > 0:
		return ORIENTATION.CW
	elif val < 0:
		return ORIENTATION.CCW
	return ORIENTATION.COLINEAR


## Return true if line segments p1q1 and p2q2 intersect.
func edges_intersect(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> bool:
	var o1 := get_orientation(p1, q1, p2)
	var o2 := get_orientation(p1, q1, q2)
	var o3 := get_orientation(p2, q2, p1)
	var o4 := get_orientation(p2, q2, q1)
	# General case
	if (o1 != o2) and (o3 != o4):
		return true

	# Special Cases
	# p1 , q1 and p2 are colinear and p2 lies on segment p1q1
	if (o1 == 0) and on_segment(p1, p2, q1):
		return true

	# p1 , q1 and q2 are colinear and q2 lies on segment p1q1
	if (o2 == 0) and on_segment(p1, q2, q1):
		return true

	# p2 , q2 and p1 are colinear and p1 lies on segment p2q2
	if (o3 == 0) and on_segment(p2, p1, q2):
		return true

	# p2 , q2 and q1 are colinear and q1 lies on segment p2q2
	if (o4 == 0) and on_segment(p2, q1, q2):
		return true

	return false


func self_intersects() -> bool:
	return edges_intersect(pt_a, pt_d, pt_b, pt_c) or edges_intersect(pt_a, pt_b, pt_d, pt_c)


func render_lines(ci: CanvasItem) -> void:
	ci.draw_line(pt_a, pt_b, color)
	ci.draw_line(pt_b, pt_c, color)
	ci.draw_line(pt_c, pt_d, color)
	ci.draw_line(pt_d, pt_a, color)


func render_points(rad: float, intensity: float, ci: CanvasItem) -> void:
	ci.draw_circle(pt_a, rad, Color(intensity, 0, 0))
	ci.draw_circle(pt_b, rad, Color(0, 0, intensity))
	ci.draw_circle(pt_c, rad, Color(0, intensity, 0))
	ci.draw_circle(pt_d, rad, Color(intensity, 0, intensity))


func get_height_average() -> float:
	return (get_height_left() + get_height_right()) / 2.0


func get_height_left() -> float:
	return pt_a.distance_to(pt_b)


func get_height_right() -> float:
	return pt_d.distance_to(pt_c)


## Returns the difference in height between the left and right sides.
func get_height_difference() -> float:
	return get_height_left() - get_height_right()


func get_length_average() -> float:
	return (get_length_top() + get_length_bottom()) / 2.0


func get_length_top() -> float:
	return pt_d.distance_to(pt_a)


func get_length_bottom() -> float:
	return pt_c.distance_to(pt_b)
