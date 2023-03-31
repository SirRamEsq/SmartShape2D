extends "res://addons/gut/test.gd"

const ActionAddCollisionNodes := preload("res://addons/rmsmartshape/actions/action_add_collision_nodes.gd")
const ActionAddPoint := preload("res://addons/rmsmartshape/actions/action_add_point.gd")
const ActionCloseShape := preload("res://addons/rmsmartshape/actions/action_close_shape.gd")
const ActionDeletePoint := preload("res://addons/rmsmartshape/actions/action_delete_point.gd")
const ActionDeleteControlPoint := preload("res://addons/rmsmartshape/actions/action_delete_control_point.gd")
const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
const ActionMakeShapeUnique := preload("res://addons/rmsmartshape/actions/action_make_shape_unique.gd")
const ActionMoveControlPoints := preload("res://addons/rmsmartshape/actions/action_move_control_points.gd")
const ActionMoveVerticies := preload("res://addons/rmsmartshape/actions/action_move_verticies.gd")
const ActionSetPivot := preload("res://addons/rmsmartshape/actions/action_set_pivot.gd")
const ActionSplitCurve := preload("res://addons/rmsmartshape/actions/action_split_curve.gd")


func test_action_add_collision_nodes() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)
	s.position = Vector2(777, 777)

	var action := ActionAddCollisionNodes.new(s)
	action.do()
	assert_true(s.get_parent() is StaticBody2D)
	assert_eq(s.get_parent().position, Vector2(777, 777))
	assert_true(s.get_parent().has_node("CollisionPolygon2D"))
	assert_eq(s.collision_polygon_node_path, NodePath("../CollisionPolygon2D"))
	action.undo()
	assert_false(s.get_parent() is StaticBody2D)
	assert_eq(s.position, Vector2(777, 777))


func test_action_add_point() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	s.add_point(Vector2(0.0, 0.0))
	assert_eq(s.get_point_count(), 1)

	var add_point := ActionAddPoint.new(s, Vector2(100.0, 0.0))
	add_point.do()
	assert_eq(s.get_point_count(), 2)
	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0)])
	add_point.undo()
	assert_eq(s.get_point_count(), 1)
	validate_positions(s, [Vector2(0.0, 0.0)])
	add_point.do()
	assert_eq(s.get_point_count(), 2)
	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0)])

	assert_false(s.is_shape_closed())
	var add_point_2 := ActionAddPoint.new(s, Vector2(100.0, 100.0))
	add_point_2.do()
	assert_eq(s.get_point_count(), 4)  ## shape should be closed by this action - so 4 points
	assert_true(s.is_shape_closed())
	add_point_2.undo()
	assert_eq(s.get_point_count(), 2)
	add_point_2.do()
	assert_eq(s.get_point_count(), 4)

	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0), Vector2(100.0, 100.0),
			Vector2(0.0, 0.0)])


func test_action_close_shape() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	s.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN])
	assert_false(s.is_shape_closed())
	assert_true(s.can_close())

	var a := ActionCloseShape.new(s)
	a.do()
	assert_true(s.is_shape_closed())
	assert_false(s.can_close())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])
	a.undo()
	assert_false(s.is_shape_closed())
	assert_true(s.can_close())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN])


func test_action_delete_control_point() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	var key := s.add_point(Vector2.UP)
	s.set_point_in(key, Vector2(5, 5))
	s.set_point_out(key, Vector2(15, 15))
	assert_eq(s.get_point_in(key), Vector2(5, 5))
	assert_eq(s.get_point_out(key), Vector2(15, 15))

	var a1 := ActionDeleteControlPoint.new(s, key, ActionDeleteControlPoint.PointType.POINT_IN)
	a1.do()
	assert_eq(s.get_point_in(key), Vector2.ZERO)
	assert_eq(s.get_point_out(key), Vector2(15, 15))
	a1.undo()
	assert_eq(s.get_point_in(key), Vector2(5, 5))
	assert_eq(s.get_point_out(key), Vector2(15, 15))

	var a2 := ActionDeleteControlPoint.new(s, key, ActionDeleteControlPoint.PointType.POINT_OUT)
	a2.do()
	assert_eq(s.get_point_in(key), Vector2(5, 5))
	assert_eq(s.get_point_out(key), Vector2.ZERO)
	a2.undo()
	assert_eq(s.get_point_in(key), Vector2(5, 5))
	assert_eq(s.get_point_out(key), Vector2(15, 15))


func test_action_delete_point() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	s.add_points([Vector2.UP, Vector2.RIGHT])
	assert_eq(s.get_point_count(), 2)

	s.set_point_in(s.get_point_key_at_index(0), Vector2(-1, -1))
	s.set_point_out(s.get_point_key_at_index(0), Vector2(-5, -5))

	var a1 := ActionDeletePoint.new(s, s.get_point_key_at_index(0))
	a1.do()
	assert_eq(s.get_point_count(), 1)
	validate_positions(s, [Vector2.RIGHT])
	a1.undo()
	assert_eq(s.get_point_count(), 2)
	validate_positions(s, [Vector2.UP, Vector2.RIGHT])
	assert_eq(s.get_point_in(s.get_point_key_at_index(0)), Vector2(-1, -1))
	assert_eq(s.get_point_out(s.get_point_key_at_index(0)), Vector2(-5, -5))

	s.add_point(Vector2.DOWN)
	s.close_shape()
	assert_eq(s.get_point_count(), 4)
	assert_true(s.is_shape_closed())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])

	# Test deleting closing point.
	var a2 := ActionDeletePoint.new(s, s.get_point_key_at_index(0))
	a2.do()
	assert_eq(s.get_point_count(), 2)
	assert_false(s.is_shape_closed())
	validate_positions(s, [Vector2.RIGHT, Vector2.DOWN])
	a2.undo()
	assert_eq(s.get_point_count(), 4)
	assert_true(s.is_shape_closed())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])


func test_action_invert_orientation() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	var a := ActionInvertOrientation.new(s)
	var cw_sequence := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var ccw_sequence := [Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT, Vector2.UP]

	# Test with clockwise sequence.
	s.add_points(cw_sequence)
	validate_positions(s, cw_sequence)
	a.do()
	validate_positions(s, cw_sequence)
	a.undo()
	validate_positions(s, cw_sequence)

	# Test with counter-clockwise sequence.
	s.clear_points()
	s.add_points(ccw_sequence)
	validate_positions(s, ccw_sequence)
	a.do()
	validate_positions(s, cw_sequence)
	a.undo()
	validate_positions(s, ccw_sequence)


func test_action_make_shape_unique() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	var original_array := SS2D_Point_Array.new()
	original_array.add_point(Vector2.UP)
	var original_array_uid: int = original_array.get_instance_id()
	s.set_point_array(original_array)
	assert_eq(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])

	var action := ActionMakeShapeUnique.new(s)

	action.do()
	assert_ne(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])

	action.undo()
	assert_eq(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])


func test_action_move_control_points() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	# Setup.
	s.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN])
	s.close_shape()
	var key := s.get_point_key_at_index(0)
	# New points in/out
	s.set_point_in(key, Vector2(-5, -5))
	s.set_point_out(key, Vector2(-10, -10))

	var action := ActionMoveControlPoints.new(
		s, [key], [Vector2(5, 5)], [Vector2(10, 10)])  # Old points in/out provided as args.
	action.do()
	# Should be new points.
	assert_eq(s.get_point_in(key), Vector2(-5, -5))
	assert_eq(s.get_point_out(key), Vector2(-10, -10))
	action.undo()
	# Should be old points.
	assert_eq(s.get_point_in(key), Vector2(5, 5))
	assert_eq(s.get_point_out(key), Vector2(10, 10))


func test_action_move_verticies() -> void:
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(s)

	var new_positions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
	var old_positions := [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
	s.add_points(new_positions)

	var action := ActionMoveVerticies.new(s, s.get_all_point_keys(), old_positions)
	action.do()
	validate_positions(s, new_positions)
	action.undo()
	validate_positions(s, old_positions)
	action.do()
	validate_positions(s, new_positions)


func test_action_set_pivot() -> void:
	var parent := Node2D.new()
	var s := SS2D_Shape_Closed.new()
	add_child_autofree(parent)
	parent.add_child(s)

	var key := s.add_point(Vector2.ZERO)

	var t := Transform2D()
	var action := ActionSetPivot.new(s, t, Vector2(100.0, 100.0))
	action.do()
	assert_eq(s.get_point_position(key), Vector2(-100.0, -100.0))
	action.undo()
	assert_eq(s.get_point_position(key), Vector2.ZERO)


func test_action_split_curve() -> void:
	var s := SS2D_Shape_Open.new()
	add_child_autofree(s)

	var t := Transform2D()
	s.add_points([Vector2(0, 0), Vector2(100, 100)])

	var action := ActionSplitCurve.new(s, 1, Vector2(50, 50), t)
	action.do()
	validate_positions(s, [Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])
	action.undo()
	validate_positions(s, [Vector2(0, 0), Vector2(100, 100)])
	action.do()
	validate_positions(s, [Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])


func validate_positions(s: SS2D_Shape_Base, positions: PackedVector2Array) -> void:
	assert_eq(s.get_point_count(), positions.size())
	if s.get_point_count() != positions.size():
		return
	for i in s.get_point_count():
		assert_eq(s.get_point_position(s.get_point_key_at_index(i)), positions[i])

