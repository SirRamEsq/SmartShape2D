extends "res://addons/gut/test.gd"

var TEST_TEXTURE = load("res://gut/unit/test.png")

func test_adjust_point_index():
	var shape = RMSS2D_Shape_Closed.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()
	var keys = []
	for i in range(0, points.size(), 1):
		var p = points[i]
		keys.push_back(shape.add_point(p))

	assert_eq(shape.adjust_add_point_index(0), 1)
	var point_count = shape.get_point_count()
	assert_eq(shape.adjust_add_point_index(-1), point_count - 1)
	assert_eq(shape.adjust_add_point_index(point_count - 1), point_count - 1)
	assert_eq(shape.adjust_add_point_index(80), point_count - 1)


func test_edges_intersect():
	var p1 = Vector2(0,0)
	var p2 = Vector2(-100,0)
	var p3 = Vector2(100,0)
	var p4 = Vector2(-50,-50)
	var p5 = Vector2(50,50)
	var p6 = Vector2(-1,0)
	assert_true(RMSS2D_Shape_Closed.do_edges_intersect(p1, p1, p1, p1))
	assert_true(RMSS2D_Shape_Closed.do_edges_intersect(p2, p3, p4, p5))
	assert_true(RMSS2D_Shape_Closed.do_edges_intersect(p1, p3, p4, p5))
	assert_true(RMSS2D_Shape_Closed.do_edges_intersect(p1, p2, p4, p5))
	assert_true(RMSS2D_Shape_Closed.do_edges_intersect(p3, p1, p4, p5))
	assert_false(RMSS2D_Shape_Closed.do_edges_intersect(p2, p6, p4, p5))
	assert_false(RMSS2D_Shape_Closed.do_edges_intersect(p2, p6, p1, p5))
	assert_false(RMSS2D_Shape_Closed.do_edges_intersect(p2, p6, p1, p4))

func test_scale_points():
	var points = [Vector2(-100, -100), Vector2(100, -100), Vector2(100, 100), Vector2(-100, 100)]
	var tex_size = TEST_TEXTURE.get_size()
	#var expected_points = [Vector2(-100, -100 + tex_size.y), Vector2(100,
	var no_scale_points = RMSS2D_Shape_Closed.scale_points(points, 0.0)
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = no_scale_points[i]
		assert_eq(p1, p2)
	var scale_out_points = RMSS2D_Shape_Closed.scale_points(points, tex_size.x * 1.5)
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = scale_out_points[i]
		assert_almost_eq((p2 - p1).length(), tex_size.x * 1.5, 0.1)
	gut.p(scale_out_points)
	var scale_in_points = RMSS2D_Shape_Closed.scale_points(points, tex_size.x * -1.5)
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = scale_in_points[i]
		assert_almost_eq((p2 - p1).length(), tex_size.x * 1.5, 0.1)
	gut.p(scale_in_points)


func test_add_points():
	var shape = RMSS2D_Shape_Closed.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()

	var keys = []
	assert_eq(shape.get_point_count(), 0)

	keys.push_back(shape.add_point(points[0]))
	assert_eq(shape.get_point_count(), 1)
	assert_eq(shape.get_point_index(keys[0]), 0)

	keys.push_back(shape.add_point(points[1]))
	assert_eq(shape.get_point_count(), 2)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[1]), 1)

	keys.push_back(shape.add_point(points[2]))
	keys.push_back(shape.get_point_key_at_index(3))
	assert_eq(shape.get_point_count(), 4)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[1]), 1)
	assert_eq(shape.get_point_index(keys[2]), 2)
	assert_eq(shape.get_point_index(keys[3]), 3)

	# Ensure that the first point only matches the final point
	assert_false(shape.get_point_at_index(0).equals(shape.get_point_at_index(2)))
	assert_true(shape.get_point_at_index(0).equals(shape.get_point_at_index(3)))

	keys.push_back(shape.add_point(points[3]))
	assert_eq(shape.get_point_count(), 5)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[1]), 1)
	assert_eq(shape.get_point_index(keys[2]), 2)
	assert_eq(shape.get_point_index(keys[4]), 3)
	assert_eq(shape.get_point_index(keys[3]), 4)

	keys.push_back(shape.add_point(points[4], 0))
	assert_eq(shape.get_point_count(), 6)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[1]), 2)
	assert_eq(shape.get_point_index(keys[2]), 3)
	assert_eq(shape.get_point_index(keys[4]), 4)
	assert_eq(shape.get_point_index(keys[5]), 1)
	assert_eq(shape.get_point_index(keys[3]), 5)

	keys.push_back(shape.add_point(points[5], 6))
	assert_eq(shape.get_point_count(), 7)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[1]), 2)
	assert_eq(shape.get_point_index(keys[2]), 3)
	assert_eq(shape.get_point_index(keys[4]), 4)
	assert_eq(shape.get_point_index(keys[5]), 1)
	assert_eq(shape.get_point_index(keys[6]), 5)
	assert_eq(shape.get_point_index(keys[3]), 6)

	keys.push_back(shape.add_point(points[5], 80))
	assert_eq(shape.get_point_count(), 8)
	assert_eq(shape.get_point_index(keys[0]), 0)
	assert_eq(shape.get_point_index(keys[5]), 1)
	assert_eq(shape.get_point_index(keys[1]), 2)
	assert_eq(shape.get_point_index(keys[2]), 3)
	assert_eq(shape.get_point_index(keys[4]), 4)
	assert_eq(shape.get_point_index(keys[6]), 5)
	assert_eq(shape.get_point_index(keys[7]), 6)
	assert_eq(shape.get_point_index(keys[3]), 7)

	keys.push_back(shape.add_point(points[6], 3))
	assert_eq(keys[keys.size() - 1], shape.get_point_key_at_index(3))
	assert_eq(shape.get_point_index(keys[keys.size() - 1]), 3)


func get_clockwise_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(0, 100),
		Vector2(-25, 125),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]
