tool
extends Reference
class_name SS2D_Quad

enum CORNER { NONE = 0, OUTER, INNER }

var pt_a: Vector2
var pt_b: Vector2
var pt_c: Vector2
var pt_d: Vector2

var texture: Texture = null
var texture_normal: Texture = null
var color: Color = Color(1.0, 1.0, 1.0, 1.0)

var flip_texture: bool = false
var control_point_index: int

# Contains value from CORNER enum
var corner: int = 0

# EXISTS FOR LEGACY REASONS, THIS PROPERTY IS DEPRECATED
var width_factor: float = 1.0


func _to_string() -> String:
	return "[Quad] A:%s B:%s C:%s D:%s | Corner: %s" % [pt_a, pt_b, pt_c, pt_d, corner]


func duplicate() -> SS2D_Quad:
	var q = __new()
	q.pt_a = pt_a
	q.pt_b = pt_b
	q.pt_c = pt_c
	q.pt_d = pt_d

	q.texture = texture
	q.texture_normal = texture_normal
	q.color = color

	q.flip_texture = flip_texture
	q.width_factor = width_factor
	q.control_point_index = control_point_index

	q.corner = corner
	return q


func _init(
	a: Vector2 = Vector2.ZERO,
	b: Vector2 = Vector2.ZERO,
	c: Vector2 = Vector2.ZERO,
	d: Vector2 = Vector2.ZERO,
	t: Texture = null,
	tn: Texture = null,
	f: bool = false
):
	pt_a = a
	pt_b = b
	pt_c = c
	pt_d = d
	texture = t
	texture_normal = tn
	flip_texture = f


func get_rotation() -> float:
	return SS2D_NormalRange.get_angle_from_vector(pt_c - pt_a)


func get_length_average() -> float:
	return (get_length_top() + get_length_bottom()) / 2.0


func get_length_top() -> float:
	return pt_d.distance_to(pt_a)


func get_length_bottom() -> float:
	return pt_c.distance_to(pt_b)


func render_lines(ci: CanvasItem):
	ci.draw_line(pt_a, pt_b, color)
	ci.draw_line(pt_b, pt_c, color)
	ci.draw_line(pt_c, pt_d, color)
	ci.draw_line(pt_d, pt_a, color)


func render_points(rad: float, intensity: float, ci: CanvasItem):
	ci.draw_circle(pt_a, rad, Color(intensity, 0, 0))
	ci.draw_circle(pt_b, rad, Color(0, 0, intensity))
	ci.draw_circle(pt_c, rad, Color(0, intensity, 0))
	ci.draw_circle(pt_d, rad, Color(intensity, 0, intensity))


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func get_height_average() -> float:
	return (get_height_left() + get_height_right()) / 2.0


func get_height_left() -> float:
	return pt_a.distance_to(pt_b)


func get_height_right() -> float:
	return pt_d.distance_to(pt_c)
