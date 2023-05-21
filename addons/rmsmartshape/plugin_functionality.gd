@tool
extends RefCounted

## - Everything in this script should be static
## - There is one reason to have code in this script
##		1. To separate out code from the main plugin script to ease testing
##
## Common Abbreviations
## et = editor transform (viewport's canvas transform)

# --- VERTS

static func get_intersecting_control_point_in(
	s: SS2D_Shape, et: Transform2D, mouse_pos: Vector2, grab_threshold: float
) -> Array[int]:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, true)


static func get_intersecting_control_point_out(
	s: SS2D_Shape, et: Transform2D, mouse_pos: Vector2, grab_threshold: float
) -> Array[int]:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, false)


static func _get_intersecting_control_point(
	s: SS2D_Shape, et: Transform2D, mouse_pos: Vector2, grab_threshold: float, _in: bool
) -> Array[int]:
	var points: Array[int] = []
	var xform: Transform2D = et * s.get_global_transform()
	for i in s.get_point_count():
		var key: int = s.get_point_key_at_index(i)
		var vec_pos: Vector2 = s.get_point_position(key)
		var c_pos := Vector2.ZERO
		if _in:
			c_pos = s.get_point_in(key)
		else:
			c_pos = s.get_point_out(key)
		if c_pos == Vector2.ZERO:
			continue
		var final_pos := vec_pos + c_pos
		final_pos = xform * final_pos
		if final_pos.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(key)

	return points
