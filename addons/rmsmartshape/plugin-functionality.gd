tool
extends Reference

"""
- This script defines the much of the functionality of the plugin
- It is kept separate from the main plugin to ease testing

Common Abbreviations
et = editor transform (viewport's canvas transform)
"""

#########
# VERTS #
#########
static func get_intersecting_control_point_in(
	s: RMSS2D_Shape_Base, et: Transform2D, mouse_pos: Vector2, grab_threshold: float
) -> Array:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, true)

static func get_intersecting_control_point_out(
	s: RMSS2D_Shape_Base, et: Transform2D, mouse_pos: Vector2, grab_threshold: float
) -> Array:
	return _get_intersecting_control_point(s, et, mouse_pos, grab_threshold, false)

static func _get_intersecting_control_point(
	s: RMSS2D_Shape_Base, et: Transform2D, mouse_pos: Vector2, grab_threshold: float, _in: bool
) -> Array:
	var points = []
	var xform: Transform2D = et * s.get_global_transform()
	for i in range(0, s.get_point_count(), 1):
		var key = s.get_point_key_at_index(i)
		var vec = s.get_point_position(key)
		var c_pos = vec
		if _in:
			c_pos += s.get_point_in(key)
		else:
			c_pos += s.get_point_out(key)
		c_pos = xform.xform(c_pos)
		if c_pos.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(key)

	return points

###########
# ACTIONS #
###########
static func action_set_pivot(
	e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, et: Transform2D, pos: Vector2
):
	var old_pos = et.xform(s.get_parent().get_global_transform().xform(s.position))
	undo.create_action("Set Pivot")
	undo.add_do_method(e, "_set_pivot", pos)
	undo.add_undo_method(e, "_set_pivot", et.affine_inverse().xform(old_pos))
	undo.add_do_method(e, "update_overlays")
	undo.add_undo_method(e, "update_overlays")
	undo.commit_action()

static func action_move_verticies(e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, action):
	undo.create_action("Move Vertex")

	for i in range(0, action.keys.size(), 1):
		var key = action.keys[i]
		var from_position = action.starting_positions[i]
		var this_position = s.get_point_position(key)
		undo.add_do_method(s, "set_point_position", key, this_position)
		undo.add_undo_method(s, "set_point_position", key, from_position)

	undo.add_do_method(e, "update_overlays")
	undo.add_undo_method(e, "update_overlays")
	undo.commit_action()

static func action_move_control_points(
	e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, action, _in: bool, _out: bool
):
	if not _in and not _out:
		return
	undo.create_action("Move Control Point")

	undo.add_do_method(s, "set_as_dirty")
	undo.add_do_method(e, "update_overlays")

	for i in range(0, action.keys.size(), 1):
		var key = action.keys[i]
		var from_position_in = action.starting_positions_control_in[i]
		var from_position_out = action.starting_positions_control_out[i]
		if _in:
			undo.add_undo_method(s, "set_point_in", key, from_position_in)
		if _out:
			undo.add_undo_method(s, "set_point_out", key, from_position_out)

	undo.add_undo_method(s, "set_as_dirty")
	undo.add_undo_method(e, "update_overlays")
	undo.commit_action()

static func action_delete_point_in(e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, key: int):
	var from_position_in = s.get_point_in(key)
	undo.create_action("Delete Control Point In")

	undo.add_do_method(s, "set_point_in", key, Vector2.ZERO)
	undo.add_do_method(e, "update_overlays")

	undo.add_undo_method(s, "set_point_in", key, from_position_in)
	undo.add_undo_method(e, "update_overlays")

	undo.commit_action()
	action_invert_orientation(undo, s)

static func action_delete_point_out(e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, key: int):
	var from_position_out = s.get_point_out(key)
	undo.create_action("Delete Control Point Out")

	undo.add_do_method(s, "set_point_out", key, Vector2.ZERO)
	undo.add_do_method(e, "update_overlays")

	undo.add_undo_method(s, "set_point_out", key, from_position_out)
	undo.add_undo_method(e, "update_overlays")

	undo.commit_action()
	action_invert_orientation(undo, s)

static func get_constrained_points_to_delete(s: RMSS2D_Shape_Base, k: int, keys = []):
	keys.push_back(k)
	var constraints = s.get_point_constraints(k)
	for tuple in constraints:
		var constraint = constraints[tuple]
		if constraint == RMSS2D_Point_Array.CONSTRAINT.NONE:
			continue
		var k2 = RMSS2D_Point_Array.get_other_value_from_tuple(tuple, k)
		if constraint & RMSS2D_Point_Array.CONSTRAINT.ALL:
			if not keys.has(k2):
				get_constrained_points_to_delete(s, k2, keys)
	return keys

static func action_delete_point(undo: UndoRedo, s: RMSS2D_Shape_Base, first_key: int):
	var dupe = s.get_point_array().duplicate(true)
	var keys = get_constrained_points_to_delete(s, first_key)
	undo.create_action("Delete Point")
	for key in keys:
		undo.add_do_method(s, "remove_point", key)
	undo.add_undo_method(s, "set_point_array", dupe)
	undo.commit_action()
	action_invert_orientation(undo, s)

static func action_add_point(e: EditorPlugin, undo: UndoRedo, s: RMSS2D_Shape_Base, new_point: Vector2) -> int:
	"""
	Will return key of added point
	"""
	var idx = -1
	var new_key = s.get_next_key()
	undo.create_action("Add Point: %s" % new_point)
	undo.add_do_method(s, "add_point", new_point, idx, new_key)
	undo.add_undo_method(s, "remove_point", new_key)
	undo.add_do_method(e, "update_overlays")
	undo.add_undo_method(e, "update_overlays")
	undo.commit_action()
	action_invert_orientation(undo, s)
	return new_key

static func action_split_curve(
	e: EditorPlugin,
	undo: UndoRedo,
	s: RMSS2D_Shape_Base,
	idx: int,
	gpoint: Vector2,
	xform: Transform2D
):
	"""
	Will split the shape at the given index
	The key of the new point will be returned
	If the orientation is changed, idx will be updated
	"""
	idx = s.adjust_add_point_index(idx)
	undo.create_action("Split Curve")
	undo.add_do_method(s, "add_point", xform.affine_inverse().xform(gpoint), idx)
	undo.add_undo_method(s, "remove_point_at_index", idx)
	undo.add_do_method(e, "update_overlays")
	undo.add_undo_method(e, "update_overlays")
	undo.commit_action()
	var key = s.get_point_key_at_index(idx)
	action_invert_orientation(undo, s)
	return key

static func should_invert_orientation(s: RMSS2D_Shape_Base) -> bool:
	if s == null:
		return false
	if s is RMSS2D_Shape_Open:
		return false
	return not s.are_points_clockwise() and s.get_point_count() >= 3

static func action_invert_orientation(undo: UndoRedo, s: RMSS2D_Shape_Base) -> bool:
	"""
	Will reverse the orientation of the shape verticies
	This does not create or commit an undo action on its own
	It's meant to be included with another action
	Therefore, the function should be called between a block like so:
		undo.create_action("xxx")
		action_invert_orientation()-
		undo.commit_action()
	"""
	if should_invert_orientation(s):
		undo.create_action("Invert Orientation")
		undo.add_do_method(s, "invert_point_order")
		undo.add_undo_method(s, "invert_point_order")

		#undo.add_do_method(action, "invert", s.get_point_count())
		#undo.add_undo_method(action, "invert", s.get_point_count())
		undo.commit_action()
		return true
	return false
