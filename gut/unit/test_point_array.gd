extends "res://addons/gut/test.gd"

func test_point_order():
	var p_array = RMSS2D_Point_Array.new()
	var points = {}
	for p in generate_points():
		var new_key = p_array.add_point(p)
		assert_false(points.has(new_key), "Key: '%s' shouldn't exist" % new_key)
		points[new_key] = p
	var keys = points.keys()
	for i in range(0, keys.size(), 1):
		assert_eq(p_array.get_point_index(keys[i]), i)
	p_array.set_point_index(keys[5], 7)
	assert_eq(p_array.get_point_index(keys[5]), 7)
	assert_eq(p_array.get_point_index(keys[6]), 5)
	assert_eq(p_array.get_point_index(keys[7]), 6)
	p_array.set_point_index(keys[6], 3)
	assert_eq(p_array.get_point_index(keys[5]), 7)
	assert_eq(p_array.get_point_index(keys[7]), 6)
	assert_eq(p_array.get_point_index(keys[4]), 5)
	assert_eq(p_array.get_point_index(keys[3]), 4)
	assert_eq(p_array.get_point_index(keys[6]), 3)
	assert_eq(p_array.get_point_index(keys[2]), 2)
	assert_eq(p_array.get_point_index(keys[1]), 1)
	assert_eq(p_array.get_point_index(keys[0]), 0)
	p_array.remove_point(keys[6])
	assert_eq(p_array.get_point_index(keys[5]), 6)
	assert_eq(p_array.get_point_index(keys[7]), 5)
	assert_eq(p_array.get_point_index(keys[4]), 4)
	assert_eq(p_array.get_point_index(keys[3]), 3)
	assert_eq(p_array.get_point_index(keys[2]), 2)
	assert_eq(p_array.get_point_index(keys[1]), 1)
	assert_eq(p_array.get_point_index(keys[0]), 0)
	keys.push_back(p_array.add_point(Vector2(80, 80)))
	assert_eq(p_array.get_point_index(keys[8]), 7)
	assert_eq(p_array.get_point_index(keys[5]), 6)
	assert_eq(p_array.get_point_index(keys[7]), 5)
	assert_eq(p_array.get_point_index(keys[4]), 4)
	assert_eq(p_array.get_point_index(keys[3]), 3)
	assert_eq(p_array.get_point_index(keys[2]), 2)
	assert_eq(p_array.get_point_index(keys[1]), 1)
	assert_eq(p_array.get_point_index(keys[0]), 0)

func test_point_constraints():
	var p_array = RMSS2D_Point_Array.new()
	var points = {}
	for p in generate_points():
		points[p_array.add_point(p)] = p
	var keys = points.keys()
	p_array.add_constraint(keys[1], keys[2], RMSS2D_Point_Array.CONSTRAINT.ALL)
	assert_eq(p_array.get_point_position(keys[1]), Vector2(10,10))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(10,10))

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
