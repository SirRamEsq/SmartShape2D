extends "res://addons/gut/test.gd"

var TEST_TEXTURE: Texture2D = preload("res://tests/unit/test.png")


func test_adjust_point_index() -> void:
	var pa := SS2D_Point_Array.new()
	pa.add_points(get_clockwise_points())
	var point_count := pa.get_point_count()

	assert_eq(pa._adjust_add_point_index(0), 0)
	assert_eq(pa._adjust_add_point_index(-1), -1)
	assert_eq(pa._adjust_add_point_index(point_count - 1), point_count - 1)
	assert_eq(pa._adjust_add_point_index(80), 80)

	pa.close_shape()

	assert_eq(pa._adjust_add_point_index(0), 1)
	assert_eq(pa._adjust_add_point_index(-1), point_count - 1)
	assert_eq(pa._adjust_add_point_index(point_count - 1), point_count - 1)
	assert_eq(pa._adjust_add_point_index(80), point_count - 1)


func test_add_points() -> void:
	var shape := SS2D_Shape_Closed.new()
	var pa := shape.get_point_array()
	add_child_autofree(shape)
	var points := get_clockwise_points()

	var keys := []
	assert_eq(pa.get_point_count(), 0)

	keys.push_back(pa.add_point(points[0]))
	assert_eq(pa.get_point_count(), 1)
	assert_eq(pa.get_point_index(keys[0]), 0)

	keys.push_back(pa.add_point(points[1]))
	assert_eq(pa.get_point_count(), 2)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[1]), 1)

	keys.push_back(pa.add_point(points[2]))
	assert_eq(pa.get_point_count(), 3)
	assert_eq(pa.can_close(), true)
	keys.push_back(pa.close_shape())
	assert_eq(pa.get_point_count(), 4)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[1]), 1)
	assert_eq(pa.get_point_index(keys[2]), 2)
	assert_eq(pa.get_point_index(keys[3]), 3)

	# Ensure that the first point only matches the final point
	assert_false(pa.get_point_at_index(0).equals(pa.get_point_at_index(2)))
	assert_true(pa.get_point_at_index(0).equals(pa.get_point_at_index(3)))

	keys.push_back(pa.add_point(points[3]))
	assert_eq(pa.get_point_count(), 5)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[1]), 1)
	assert_eq(pa.get_point_index(keys[2]), 2)
	assert_eq(pa.get_point_index(keys[4]), 3)
	assert_eq(pa.get_point_index(keys[3]), 4)

	keys.push_back(pa.add_point(points[4], 0))
	assert_eq(pa.get_point_count(), 6)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[1]), 2)
	assert_eq(pa.get_point_index(keys[2]), 3)
	assert_eq(pa.get_point_index(keys[4]), 4)
	assert_eq(pa.get_point_index(keys[5]), 1)
	assert_eq(pa.get_point_index(keys[3]), 5)

	keys.push_back(pa.add_point(points[5], 6))
	assert_eq(pa.get_point_count(), 7)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[1]), 2)
	assert_eq(pa.get_point_index(keys[2]), 3)
	assert_eq(pa.get_point_index(keys[4]), 4)
	assert_eq(pa.get_point_index(keys[5]), 1)
	assert_eq(pa.get_point_index(keys[6]), 5)
	assert_eq(pa.get_point_index(keys[3]), 6)

	keys.push_back(pa.add_point(points[5], 80))
	assert_eq(pa.get_point_count(), 8)
	assert_eq(pa.get_point_index(keys[0]), 0)
	assert_eq(pa.get_point_index(keys[5]), 1)
	assert_eq(pa.get_point_index(keys[1]), 2)
	assert_eq(pa.get_point_index(keys[2]), 3)
	assert_eq(pa.get_point_index(keys[4]), 4)
	assert_eq(pa.get_point_index(keys[6]), 5)
	assert_eq(pa.get_point_index(keys[7]), 6)
	assert_eq(pa.get_point_index(keys[3]), 7)

	keys.push_back(pa.add_point(points[6], 3))
	assert_eq(keys[keys.size() - 1], pa.get_point_key_at_index(3))
	assert_eq(pa.get_point_index(keys[keys.size() - 1]), 3)


func get_clockwise_points() -> Array[Vector2]:
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
