extends "res://addons/gut/test.gd"


func test_setters():
	var wrong_node = Node2D.new()
	add_child_autofree(wrong_node)
	var shapes = [generate_closed_shape(), generate_open_shape()]
	var anchor = SS2D_Shape_Anchor.new()
	add_child_autofree(anchor)

	# Test bad path
	var bad_path = "./HERP_DERP"
	anchor.shape_path = bad_path
	assert_eq(anchor.shape_path, NodePath(bad_path))
	assert_eq(anchor.shape, null)

	# Test wrong node
	bad_path = anchor.get_path_to(wrong_node)
	anchor.shape_path = bad_path
	assert_eq(anchor.shape_path, NodePath(bad_path))
	assert_eq(anchor.shape, null)

	for shape in shapes:
		var points = shape.get_vertices()

		var valid_path = anchor.get_path_to(shape)
		# Check shape is sibling node
		assert_eq(valid_path, NodePath("../%s" % shape.name))

		# Test valid path
		anchor.shape_path = valid_path
		assert_eq(anchor.shape_path, valid_path)
		assert_ne(anchor.shape, null)

		# Test setting index
		for i in range(points.size() - 1):
			anchor.shape_point_index = i
			assert_eq(anchor.shape_point_index, i)

		# Ensure final index cannot be chosen
		anchor.shape_point_index = points.size() - 1
		assert_eq(anchor.shape_point_index, 0)

		# Test OutOfBounds
		anchor.shape_point_index = points.size() + 3
		assert_eq(anchor.shape_point_index, 4)

		# Test Negative (should be final valid point)
		anchor.shape_point_index = -10000
		assert_eq(anchor.shape_point_index, points.size() - 2)


func generate_closed_shape() -> SS2D_Shape_Closed:
	var shape = SS2D_Shape_Closed.new()
	shape.name = "Closed"
	add_child_autofree(shape)
	var points = generate_points()
	shape.add_points(points)
	assert_eq(shape.get_point_count(), points.size() + 1)
	return shape


func generate_open_shape() -> SS2D_Shape_Open:
	var shape = SS2D_Shape_Open.new()
	shape.name = "Open"
	add_child_autofree(shape)
	var points = generate_points()
	shape.add_points(points)
	assert_eq(shape.get_point_count(), points.size())
	return shape


func generate_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(10, 10),
		Vector2(20, 20),
		Vector2(30, 30),
		Vector2(40, 40),
		Vector2(50, 50),
		Vector2(60, 60),
		Vector2(70, 70)
	]
