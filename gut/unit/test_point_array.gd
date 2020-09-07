extends "res://addons/gut/test.gd"


func test_point_order():
	var p_array = SS2D_Point_Array.new()
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
	var p_array = SS2D_Point_Array.new()
	var points = {}
	for p in generate_points():
		points[p_array.add_point(p)] = p
	var keys = points.keys()

	assert_eq(p_array.get_point_position(keys[1]), Vector2(10, 10))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(20, 20))

	# CONSTRAIN POINTS
	p_array.set_constraint(keys[1], keys[2], SS2D_Point_Array.CONSTRAINT.ALL)
	p_array.set_constraint(keys[2], keys[3], SS2D_Point_Array.CONSTRAINT.ALL)
	p_array.set_constraint(keys[3], keys[4], SS2D_Point_Array.CONSTRAINT.ALL)
	p_array.set_constraint(keys[4], keys[5], SS2D_Point_Array.CONSTRAINT.AXIS_X)
	p_array.set_constraint(keys[4], keys[6], SS2D_Point_Array.CONSTRAINT.AXIS_Y)
	assert_eq(p_array.get_point_position(keys[1]), Vector2(10, 10))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(10, 10))
	assert_eq(p_array.get_point_position(keys[3]), Vector2(10, 10))
	assert_eq(p_array.get_point_position(keys[4]), Vector2(10, 10))
	assert_eq(p_array.get_point_position(keys[5]), Vector2(10, 50))
	assert_eq(p_array.get_point_position(keys[6]), Vector2(60, 10))

	# SET POSITION
	p_array.set_point_position(keys[1], Vector2(123, 321))
	assert_eq(p_array.get_point_position(keys[1]), Vector2(123, 321))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(123, 321))
	assert_eq(p_array.get_point_position(keys[3]), Vector2(123, 321))
	assert_eq(p_array.get_point_position(keys[4]), Vector2(123, 321))
	assert_eq(p_array.get_point_position(keys[5]), Vector2(123, 50))
	assert_eq(p_array.get_point_position(keys[6]), Vector2(60, 321))

	# REMOVE CONSTRAINT
	assert_eq(p_array.get_point_constraints(keys[1]).size(), 1)
	assert_eq(p_array.get_point_constraints(keys[2]).size(), 2)
	assert_eq(p_array.get_point_constraints(keys[3]).size(), 2)
	p_array.set_constraint(keys[1], keys[2], SS2D_Point_Array.CONSTRAINT.NONE)
	assert_eq(p_array.get_point_constraints(keys[1]).size(), 0)
	assert_eq(p_array.get_point_constraints(keys[2]).size(), 1)
	assert_eq(p_array.get_point_constraints(keys[3]).size(), 2)
	p_array.set_point_position(keys[1], Vector2(777, 888))
	assert_eq(p_array.get_point_position(keys[1]), Vector2(777, 888))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(123, 321))

	# POINT IN/OUT AND PROPERTIES
	assert_eq(p_array.get_point_in(keys[3]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[3]), Vector2(0, 0))
	assert_eq(p_array.get_point_properties(keys[3]).flip, false)
	assert_eq(p_array.get_point_in(keys[4]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[4]), Vector2(0, 0))
	assert_eq(p_array.get_point_properties(keys[4]).flip, false)
	p_array.set_point_in(keys[3], Vector2(33, 44))
	p_array.set_point_out(keys[3], Vector2(11, 22))
	var props = p_array.get_point_properties(keys[3])
	props.flip = true
	p_array.set_point_properties(keys[3], props)

	assert_eq(p_array.get_point_in(keys[3]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[3]), Vector2(11, 22))
	assert_eq(p_array.get_point_properties(keys[3]).flip, true)
	assert_eq(p_array.get_point_in(keys[4]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[4]), Vector2(11, 22))
	assert_eq(p_array.get_point_properties(keys[4]).flip, true)
	assert_eq(p_array.get_point_in(keys[2]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[2]), Vector2(11, 22))
	assert_eq(p_array.get_point_properties(keys[2]).flip, true)
	assert_eq(p_array.get_point_in(keys[1]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[1]), Vector2(0, 0))
	assert_eq(p_array.get_point_properties(keys[1]).flip, false)


func test_duplicate():
	var p_array = SS2D_Point_Array.new()
	for p in generate_points():
		p_array.add_point(p)

	var other = p_array.duplicate(true)
	assert_ne(p_array, other)
	assert_ne(p_array._constraints, other._constraints)
	assert_ne(p_array._points, other._points)

	assert_eq(p_array._point_order, other._point_order)
	p_array._point_order.push_back(31337)
	assert_ne(p_array._point_order, other._point_order)
	p_array._point_order.pop_back()
	assert_eq(p_array._point_order, other._point_order)

	assert_eq(p_array._next_key, other._next_key)
	assert_eq(p_array._constraints.size(), other._constraints.size())
	assert_eq(p_array._points.size(), other._points.size())
	for i in range(0, p_array._point_order.size(), 1):
		var key1 = p_array._point_order[i]
		var key2 = other._point_order[i]
		assert_eq(key1, key2, "Same Point Order")

	for k in p_array._points:
		var p1 = p_array._points[k]
		var p2 = other._points[k]
		assert_ne(p1, p2, "Unique Point with key %s" % k)
		assert_ne(p1.properties, p2.properties)

		assert_eq(p1.get_signal_connection_list("changed").size(), 1, "SIGNALS CONNECTED")
		assert_eq(
			p1.get_signal_connection_list("changed")[0].target,
			p_array,
			"SIGNALS CONNECTED to Parent"
		)
		assert_eq(
			p2.get_signal_connection_list("changed")[0].target, other, "SIGNALS CONNECTED to Parent"
		)
		assert_eq(
			p1.get_signal_connection_list("changed").size(),
			p2.get_signal_connection_list("changed").size(),
			"SIGNALS CONNECTED Size"
		)
		assert_eq(p1.position, p2.position, "pos Same Values")
		assert_eq(p1.point_in, p2.point_in, "p_in Same Values")
		assert_eq(p1.point_out, p2.point_out, "p_out Same Values")
		assert_eq(p1.properties.texture_idx, p2.properties.texture_idx, "tex_idx Same Values")
		assert_eq(p1.properties.flip, p2.properties.flip, "flip Same Values")
		assert_eq(p1.properties.width, p2.properties.width, "width Same Values")


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
