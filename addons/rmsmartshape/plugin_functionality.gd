@tool
class_name SS2D_PluginFunctionality
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
) -> PackedInt32Array:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, true)


static func get_intersecting_control_point_out(
	s: SS2D_Shape, et: Transform2D, mouse_pos: Vector2, grab_threshold: float
) -> PackedInt32Array:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, false)


static func _get_intersecting_control_point(
	s: SS2D_Shape, et: Transform2D, mouse_pos: Vector2, grab_threshold: float, _in: bool
) -> PackedInt32Array:
	var points := PackedInt32Array()
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


static func get_next_point_index(idx: int, points: PackedVector2Array, wrap_around: bool = false) -> int:
	if wrap_around:
		return get_next_point_index_wrap_around(idx, points)
	return get_next_point_index_no_wrap_around(idx, points)


static func get_previous_point_index(idx: int, points: PackedVector2Array, wrap_around: bool = false) -> int:
	if wrap_around:
		return get_previous_point_index_wrap_around(idx, points)
	return get_previous_point_index_no_wrap_around(idx, points)


static func get_next_point_index_no_wrap_around(idx: int, points: PackedVector2Array) -> int:
	return mini(idx + 1, points.size() - 1)


static func get_previous_point_index_no_wrap_around(idx: int, _points_: PackedVector2Array) -> int:
	return maxi(idx - 1, 0)


static func get_next_point_index_wrap_around(idx: int, points: PackedVector2Array) -> int:
	return (idx + 1) % points.size()


static func get_previous_point_index_wrap_around(idx: int, points: PackedVector2Array) -> int:
	return posmod(idx - 1, points.size())


## Get the next point that doesn't share the same position with the current point.[br]
## In other words, get the next point in the array with a unique position.[br]
static func get_next_unique_point_idx(idx: int, pts: PackedVector2Array, wrap_around: bool) -> int:
	var next_idx: int = get_next_point_index(idx, pts, wrap_around)
	if next_idx == idx:
		return idx
	var pt1: Vector2 = pts[idx]
	var pt2: Vector2 = pts[next_idx]
	if pt1 == pt2:
		return get_next_unique_point_idx(next_idx, pts, wrap_around)
	return next_idx


static func get_previous_unique_point_idx(idx: int, pts: PackedVector2Array, wrap_around: bool) -> int:
	var previous_idx: int = get_previous_point_index(idx, pts, wrap_around)
	if previous_idx == idx:
		return idx
	var pt1: Vector2 = pts[idx]
	var pt2: Vector2 = pts[previous_idx]
	if pt1 == pt2:
		return get_previous_unique_point_idx(previous_idx, pts, wrap_around)
	return previous_idx


static func snap_position(
	pos_global: Vector2, snap_offset: Vector2, snap_step: Vector2, local_t: Transform2D
) -> Vector2:
	# Move global position to local position to snap in local space
	var pos_local: Vector2 = local_t * pos_global

	# Snap in local space
	var x: float = pos_local.x
	if snap_step.x != 0:
		var delta: float = fmod(pos_local.x, snap_step.x)
		# Round up
		if delta >= (snap_step.x / 2.0):
			x = pos_local.x + (snap_step.x - delta)
		# Round down
		else:
			x = pos_local.x - delta
	var y: float = pos_local.y
	if snap_step.y != 0:
		var delta: float = fmod(pos_local.y, snap_step.y)
		# Round up
		if delta >= (snap_step.y / 2.0):
			y = pos_local.y + (snap_step.y - delta)
		# Round down
		else:
			y = pos_local.y - delta

	# Transform3D local position to global position
	var pos_global_snapped := (local_t.affine_inverse() * Vector2(x, y)) + snap_offset
	#print ("%s | %s | %s | %s" % [pos_global, pos_local, Vector2(x,y), pos_global_snapped])
	return pos_global_snapped


