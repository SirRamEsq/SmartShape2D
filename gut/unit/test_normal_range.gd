extends "res://addons/gut/test.gd"


func test_range_all_inclusive():
	var nr = SS2D_NormalRange.new(0.0, 360.0)
	var vectors = [
		Vector2(1000, 0),
		Vector2(1000, 1),
		Vector2(1000, 10),
		Vector2(1000, -1),
		Vector2(1000, -10),
		Vector2(-10, 0),
		Vector2(-10, 10),
		Vector2(-10, -10),
		Vector2(-10000, -1)
	]

	for i in range(0, vectors.size(), 1):
		var v = vectors[i]
		assert_true(nr.is_in_range(v), "[%s] Not In Range: %s" % [i, v])

	nr = SS2D_NormalRange.new(0.0, 0.0)
	for i in range(0, vectors.size(), 1):
		var v = vectors[i]
		assert_true(nr.is_in_range(v), "[%s] Not In Range: %s" % [i, v])


func test_range():
	var nr = SS2D_NormalRange.new(-90.0, 90.0)
	var acceptable_vectors = [
		Vector2(10, 0), Vector2(10, 10), Vector2(10, -10), Vector2(0, 1), Vector2(0, -1)
	]
	var unacceptable_vectors = [
		Vector2(-10, 0),
		Vector2(-10, 10),
		Vector2(-10, -10),
		Vector2(-0.1, 1000),
		Vector2(-0.1, -1000)
	]

	for i in range(0, acceptable_vectors.size(), 1):
		var v = acceptable_vectors[i]
		assert_true(nr.is_in_range(v), "[%s] Not In Range: %s" % [i, v])

	nr = SS2D_NormalRange.new(0.0, 0.0)
	for i in range(0, unacceptable_vectors.size(), 1):
		var v = unacceptable_vectors[i]
		assert_true(nr.is_in_range(v), "[%s] Is In Range: %s" % [i, v])


func test_angle():
	# RIGHT
	var v1 = Vector2(1000, 0)
	var v1_angle = SS2D_NormalRange.get_angle_from_vector(v1)
	assert_eq(v1_angle, 0.0)

	# UP
	var v2 = Vector2(0, -1000)
	var v2_angle = SS2D_NormalRange.get_angle_from_vector(v2)
	assert_eq(v2_angle, 90.0)

	# LEFT
	var v3 = Vector2(-1000, 0)
	var v3_angle = SS2D_NormalRange.get_angle_from_vector(v3)
	assert_eq(v3_angle, 180.0)

	# DOWN
	var v4 = Vector2(0, 1000)
	var v4_angle = SS2D_NormalRange.get_angle_from_vector(v4)
	assert_eq(v4_angle, 270.0)
