tool
extends Reference
class_name RMSS2D_Quad

var pt_a: Vector2
var pt_b: Vector2
var pt_c: Vector2
var pt_d: Vector2

var texture: Texture = null
var texture_normal: Texture = null
var color: Color = Color(1.0, 1.0, 1.0, 1.0)

var flip_texture: bool = false
var width_factor: float = 1.0
var control_point_index: int


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
	return RMSS2D_NormalRange.get_angle_from_vector(pt_c - pt_a)


func get_length() -> float:
	return (pt_d.distance_to(pt_a) + pt_c.distance_to(pt_b)) / 2.0


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
