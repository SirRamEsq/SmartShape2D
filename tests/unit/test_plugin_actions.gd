extends "res://addons/gut/test.gd"


func test_action_add_collision_nodes() -> void:
	var container: StaticBody2D = StaticBody2D.new()
	container.name = "StaticBody2D"
	container.unique_name_in_owner = true
	add_child_autofree(container)

	var s := SS2D_Shape_Closed.new()
	s.collision_polygon_node_path = ^"asdf"
	add_child_autofree(s)

	# Add as sibling
	var action := SS2D_ActionAddCollisionNodes.new(s, null)
	action.do()
	assert_true(s.get_parent().get_child(s.get_index() + 1) is CollisionPolygon2D)
	assert_eq(s.collision_polygon_node_path, NodePath("../CollisionPolygon2D"))

	action.undo()
	await wait_frames(1)  # wait for queue_free() to take place
	assert_null(s.get_parent().get_child(s.get_index() + 1))
	assert_eq(s.collision_polygon_node_path, ^"asdf")

	# Add in container
	action = SS2D_ActionAddCollisionNodes.new(s, container)
	action.do()
	assert_true(container.get_child(0) is CollisionPolygon2D)
	assert_eq(s.collision_polygon_node_path, NodePath("../StaticBody2D/CollisionPolygon2D"))

	action.undo()
	await wait_frames(1)  # wait for queue_free() to take place
	assert_eq(container.get_child_count(), 0)
	assert_eq(s.collision_polygon_node_path, ^"asdf")


func test_action_add_point() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	pa.add_point(Vector2(0.0, 0.0))
	assert_eq(pa.get_point_count(), 1)

	var add_point := SS2D_ActionAddPoint.new(s, Vector2(100.0, 0.0))
	add_point.do()
	assert_eq(pa.get_point_count(), 2)
	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0)])
	add_point.undo()
	assert_eq(pa.get_point_count(), 1)
	validate_positions(s, [Vector2(0.0, 0.0)])
	add_point.do()
	assert_eq(pa.get_point_count(), 2)
	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0)])

	assert_false(pa.is_shape_closed())

	var add_point_2 := SS2D_ActionAddPoint.new(s, Vector2(100.0, 100.0))
	add_point_2.do()
	assert_eq(pa.get_point_count(), 3)
	assert_false(pa.is_shape_closed())
	add_point_2.undo()
	assert_eq(pa.get_point_count(), 2)
	add_point_2.do()
	assert_eq(pa.get_point_count(), 3)

	validate_positions(s, [Vector2(0.0, 0.0), Vector2(100.0, 0.0), Vector2(100.0, 100.0)])


func test_action_close_shape() -> void:
	var s := SS2D_Shape_Closed.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	pa.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN])

	assert_false(pa.is_shape_closed())
	assert_true(pa.can_close())

	var a := SS2D_ActionCloseShape.new(s)

	a.do()
	assert_true(pa.is_shape_closed())
	assert_false(pa.can_close())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])

	a.undo()
	assert_false(pa.is_shape_closed())
	assert_true(pa.can_close())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN])


func test_action_delete_control_point() -> void:
	var s := SS2D_Shape_Closed.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	var key := pa.add_point(Vector2.UP)
	pa.set_point_in(key, Vector2(5, 5))
	pa.set_point_out(key, Vector2(15, 15))
	assert_eq(pa.get_point_in(key), Vector2(5, 5))
	assert_eq(pa.get_point_out(key), Vector2(15, 15))

	var a1 := SS2D_ActionDeleteControlPoint.new(s, key, SS2D_ActionDeleteControlPoint.PointType.POINT_IN)
	a1.do()
	assert_eq(pa.get_point_in(key), Vector2.ZERO)
	assert_eq(pa.get_point_out(key), Vector2(15, 15))
	a1.undo()
	assert_eq(pa.get_point_in(key), Vector2(5, 5))
	assert_eq(pa.get_point_out(key), Vector2(15, 15))

	var a2 := SS2D_ActionDeleteControlPoint.new(s, key, SS2D_ActionDeleteControlPoint.PointType.POINT_OUT)
	a2.do()
	assert_eq(pa.get_point_in(key), Vector2(5, 5))
	assert_eq(pa.get_point_out(key), Vector2.ZERO)
	a2.undo()
	assert_eq(pa.get_point_in(key), Vector2(5, 5))
	assert_eq(pa.get_point_out(key), Vector2(15, 15))


func test_action_delete_point() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	pa.add_points([Vector2.UP, Vector2.RIGHT])
	assert_eq(pa.get_point_count(), 2)

	pa.set_point_in(pa.get_point_key_at_index(0), Vector2(-1, -1))
	pa.set_point_out(pa.get_point_key_at_index(0), Vector2(-5, -5))

	var a1 := SS2D_ActionDeletePoint.new(s, pa.get_point_key_at_index(0))
	a1.do()
	assert_eq(pa.get_point_count(), 1)
	validate_positions(s, [Vector2.RIGHT])
	a1.undo()
	assert_eq(pa.get_point_count(), 2)
	validate_positions(s, [Vector2.UP, Vector2.RIGHT])
	assert_eq(pa.get_point_in(pa.get_point_key_at_index(0)), Vector2(-1, -1))
	assert_eq(pa.get_point_out(pa.get_point_key_at_index(0)), Vector2(-5, -5))

	pa.add_point(Vector2.DOWN)
	pa.close_shape()
	assert_eq(pa.get_point_count(), 4)
	assert_true(pa.is_shape_closed())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])

	# Test deleting closing point.
	var a2 := SS2D_ActionDeletePoint.new(s, pa.get_point_key_at_index(0))
	a2.do()
	assert_eq(pa.get_point_count(), 3)
	assert_true(pa.is_shape_closed())
	validate_positions(s, [Vector2.RIGHT, Vector2.DOWN, Vector2.RIGHT])
	a2.undo()
	assert_eq(pa.get_point_count(), 4)
	assert_true(pa.is_shape_closed())
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.UP])


func test_action_invert_orientation() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	var a := SS2D_ActionInvertOrientation.new(s)
	var cw_sequence := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var ccw_sequence := [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]

	# Test with clockwise sequence.
	pa.add_points(cw_sequence)
	pa.close_shape()

	cw_sequence.push_back(cw_sequence.front())
	validate_positions(s, cw_sequence)

	a.do()
	validate_positions(s, cw_sequence)

	a.undo()
	validate_positions(s, cw_sequence)

	# Test with counter-clockwise sequence.
	pa.clear()
	pa.add_points(ccw_sequence)
	ccw_sequence.push_back(ccw_sequence.front())
	pa.close_shape()

	validate_positions(s, ccw_sequence)

	a.do()
	validate_positions(s, cw_sequence)

	a.undo()
	validate_positions(s, ccw_sequence)


func test_action_make_shape_unique() -> void:
	var s := SS2D_Shape.new()
	add_child_autofree(s)

	var original_array := SS2D_Point_Array.new()
	original_array.add_point(Vector2.UP)
	var original_array_uid: int = original_array.get_instance_id()
	s.set_point_array(original_array)
	assert_eq(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])

	var action := SS2D_ActionMakeShapeUnique.new(s)

	action.do()
	assert_ne(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])

	action.undo()
	assert_eq(s.get_point_array().get_instance_id(), original_array_uid)
	validate_positions(s, [Vector2.UP])


func test_action_move_control_points() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	# Setup.
	pa.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN])
	pa.close_shape()
	var key := pa.get_point_key_at_index(0)
	# New points in/out
	pa.set_point_in(key, Vector2(-5, -5))
	pa.set_point_out(key, Vector2(-10, -10))

	var action := SS2D_ActionMoveControlPoints.new(
		s, [key], [Vector2(5, 5)], [Vector2(10, 10)])  # Old points in/out provided as args.
	action.do()
	# Should be new points.
	assert_eq(pa.get_point_in(key), Vector2(-5, -5))
	assert_eq(pa.get_point_out(key), Vector2(-10, -10))
	action.undo()
	# Should be old points.
	assert_eq(pa.get_point_in(key), Vector2(5, 5))
	assert_eq(pa.get_point_out(key), Vector2(10, 10))


func test_action_move_verticies() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	var new_positions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
	var old_positions := [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
	pa.add_points(new_positions)

	var action := SS2D_ActionMoveVerticies.new(s, pa.get_all_point_keys(), old_positions)
	action.do()
	validate_positions(s, new_positions)
	action.undo()
	validate_positions(s, old_positions)
	action.do()
	validate_positions(s, new_positions)


func test_action_set_pivot() -> void:
	var parent := Node2D.new()
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(parent)
	parent.add_child(s)

	var key := pa.add_point(Vector2.ZERO)

	var action := SS2D_ActionSetPivot.new(s, Vector2(100.0, 100.0))
	action.do()
	assert_eq(pa.get_point_position(key), Vector2(-100.0, -100.0))
	action.undo()
	assert_eq(pa.get_point_position(key), Vector2.ZERO)


func test_action_split_curve() -> void:
	var s := SS2D_Shape.new()
	add_child_autofree(s)

	var t := Transform2D()
	s.get_point_array().add_points([Vector2(0, 0), Vector2(100, 100)])

	var action := SS2D_ActionSplitCurve.new(s, 1, Vector2(50, 50), t)
	action.do()
	validate_positions(s, [Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])
	action.undo()
	validate_positions(s, [Vector2(0, 0), Vector2(100, 100)])
	action.do()
	validate_positions(s, [Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])


func test_action_open_shape() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	add_child_autofree(s)

	pa.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])
	pa.close_shape()

	var action := SS2D_ActionOpenShape.new(s, pa.get_point_key_at_index(1))
	action.do()
	validate_positions(s, [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT])
	action.undo()
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP])


func test_action_split_shape() -> void:
	var s := SS2D_Shape.new()
	var pa := s.get_point_array()
	s.name = "Shape"
	add_child_autofree(s, true)

	pa.add_points([Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])

	var action := SS2D_ActionSplitShape.new(s, pa.get_point_key_at_index(1))
	action.do()
	validate_positions(s, [Vector2.UP, Vector2.RIGHT])
	var s2: SS2D_Shape = s.get_parent().get_node(^"Shape2")
	assert_not_null(s2)
	add_child_autofree(s2, true)
	validate_positions(s2, [Vector2.DOWN, Vector2.LEFT])

	action.undo()
	assert_null(s.get_parent().get_node(^"Shape2"))
	validate_positions(s, [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT])


func validate_positions(s: SS2D_Shape, positions: PackedVector2Array) -> void:
	var pa := s.get_point_array()
	assert_eq(pa.get_point_count(), positions.size())
	if pa.get_point_count() != positions.size():
		return
	for i in pa.get_point_count():
		assert_eq(pa.get_point_position(pa.get_point_key_at_index(i)), positions[i])
