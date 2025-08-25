extends "res://addons/gut/test.gd"


func test_point_order() -> void:
	var p_array := SS2D_Point_Array.new()
	var points := {}
	for p in generate_points():
		var new_key := p_array.add_point(p)
		assert_false(points.has(new_key), "Key: '%s' shouldn't exist" % new_key)
		points[new_key] = p
	var keys := points.keys()
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


func test_point_constraints() -> void:
	var p_array := SS2D_Point_Array.new()
	var points := {}
	for p in generate_points():
		points[p_array.add_point(p)] = p
	var keys := points.keys()

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
	p_array.remove_constraint(Vector2i(keys[1], keys[2]))
	assert_eq(p_array.get_point_constraints(keys[1]).size(), 0)
	assert_eq(p_array.get_point_constraints(keys[2]).size(), 1)
	assert_eq(p_array.get_point_constraints(keys[3]).size(), 2)
	p_array.set_point_position(keys[1], Vector2(777, 888))
	assert_eq(p_array.get_point_position(keys[1]), Vector2(777, 888))
	assert_eq(p_array.get_point_position(keys[2]), Vector2(123, 321))

	p_array.set_constraint(keys[1], keys[2], SS2D_Point_Array.CONSTRAINT.ALL)
	p_array.set_constraint(keys[1], keys[2], SS2D_Point_Array.CONSTRAINT.NONE)
	assert_eq(p_array.get_point_constraints(keys[1]).size(), 0)
	assert_eq(p_array.get_point_constraints(keys[2]).size(), 1)
	assert_eq(p_array.get_point_constraints(keys[3]).size(), 2)

	# POINT IN/OUT AND PROPERTIES
	assert_eq(p_array.get_point_in(keys[3]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[3]), Vector2(0, 0))
	assert_eq(p_array.get_point(keys[3]).flip, false)
	assert_eq(p_array.get_point_in(keys[4]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[4]), Vector2(0, 0))
	assert_eq(p_array.get_point(keys[4]).flip, false)
	p_array.set_point_in(keys[3], Vector2(33, 44))
	p_array.set_point_out(keys[3], Vector2(11, 22))

	p_array.get_point(keys[3]).flip = true

	# Other points with CONSTRAINT.PROPERTIES should also be flipped now
	assert_eq(p_array.get_point_in(keys[3]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[3]), Vector2(11, 22))
	assert_eq(p_array.get_point(keys[3]).flip, true)
	assert_eq(p_array.get_point_in(keys[4]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[4]), Vector2(11, 22))
	assert_eq(p_array.get_point(keys[4]).flip, true)
	assert_eq(p_array.get_point_in(keys[2]), Vector2(33, 44))
	assert_eq(p_array.get_point_out(keys[2]), Vector2(11, 22))
	assert_eq(p_array.get_point(keys[2]).flip, true)
	assert_eq(p_array.get_point_in(keys[1]), Vector2(0, 0))
	assert_eq(p_array.get_point_out(keys[1]), Vector2(0, 0))
	assert_eq(p_array.get_point(keys[1]).flip, false)

	# Get constraint
	assert_eq(p_array.get_point_constraint(keys[2], keys[3]), SS2D_Point_Array.CONSTRAINT.ALL)
	assert_eq(p_array.get_point_constraint(keys[4], keys[5]), SS2D_Point_Array.CONSTRAINT.AXIS_X)
	# Should not exist and return NONE
	assert_eq(p_array.get_point_constraint(keys[1], keys[1]), SS2D_Point_Array.CONSTRAINT.NONE)


# TODO Test that material overrides are correctly handled when duplicating
func test_clone() -> void:
	var p_array := SS2D_Point_Array.new()
	for p in generate_points():
		p_array.add_point(p)

	var other := p_array.clone(true)
	assert_ne(p_array, other)

	for k in p_array.get_all_point_keys():
		var p1: SS2D_Point = p_array.get_point(k)
		print("p1: ", p1.get_instance_id())
		var p2: SS2D_Point = other.get_point(k)
		print("p2: ", p2.get_instance_id())

		assert_ne(p1, p2, "Unique Point with key %s" % k)

		assert_eq(p1.get_signal_connection_list("changed").size(), 1, "SIGNALS CONNECTED")
		print(p1.get_signal_connection_list("changed")[0])

		@warning_ignore("unsafe_method_access")
		assert_eq(
			p1.get_signal_connection_list("changed")[0].callable.get_object(),
			p_array,
			"SIGNALS CONNECTED to Parent"
		)
		@warning_ignore("unsafe_method_access")
		assert_eq(
			p2.get_signal_connection_list("changed")[0].callable.get_object(),
			other,
			"SIGNALS CONNECTED to Parent"
		)
		assert_eq(
			p1.get_signal_connection_list("changed").size(),
			p2.get_signal_connection_list("changed").size(),
			"SIGNALS CONNECTED Size"
		)
		assert_eq(p1.position, p2.position, "pos Same Values")
		assert_eq(p1.point_in, p2.point_in, "p_in Same Values")
		assert_eq(p1.point_out, p2.point_out, "p_out Same Values")
		assert_eq(p1.texture_idx, p2.texture_idx, "tex_idx Same Values")
		assert_eq(p1.flip, p2.flip, "flip Same Values")
		assert_eq(p1.width, p2.width, "width Same Values")

	# Run these tests after checking for point uniqueness because they modify the point array
	assert_eq(p_array.get_next_key(), other.get_next_key())
	p_array.reserve_key()
	assert_ne(p_array.get_next_key(), other.get_next_key())

	assert_eq(p_array.get_point_constraints_tuples(0), other.get_point_constraints_tuples(0))
	p_array.set_constraint(0, 1, SS2D_Point_Array.CONSTRAINT.ALL)
	assert_eq(p_array.get_point_constraints_tuples(0).size(), 1)
	assert_eq(other.get_point_constraints_tuples(0).size(), 0)

	assert_eq(p_array.get_point_count(), other.get_point_count())
	var added_key := p_array.add_point(Vector2.ONE)
	assert_ne(p_array.get_point_count(), other.get_point_count())
	p_array.remove_point(added_key)

	assert_eq(p_array.get_all_point_keys(), other.get_all_point_keys())
	p_array.set_point_order([2, 1, 0])
	assert_ne(p_array.get_all_point_keys(), other.get_all_point_keys())


func test_material_override_add_delete() -> void:
	var mmat1 := SS2D_Material_Edge_Metadata.new()
	var mmat2 := SS2D_Material_Edge_Metadata.new()
	var pa := SS2D_Point_Array.new()

	# Add
	assert_eq(0, pa.get_material_overrides().size())
	pa.set_material_override(Vector2i(0,1), mmat1)
	assert_eq(1, pa.get_material_overrides().size())
	pa.set_material_override(Vector2i(1,0), mmat1)
	assert_eq(1, pa.get_material_overrides().size())
	pa.set_material_override(Vector2i(2,1), mmat2)
	assert_eq(2, pa.get_material_overrides().size())

	assert_true(mmat1.is_connected("changed", pa._on_material_override_changed))
	assert_true(mmat2.is_connected("changed", pa._on_material_override_changed))


	# Get
	assert_eq(null, pa.get_material_override(Vector2i(5,1)))
	assert_eq(mmat1, pa.get_material_override(Vector2i(0,1)))
	assert_eq(mmat2, pa.get_material_override(Vector2i(2,1)))


	# Has
	assert_false(pa.has_material_override(Vector2i(5,1)))
	assert_true(pa.has_material_override(Vector2i(0,1)))
	assert_true(pa.has_material_override(Vector2i(2,1)))


	# Overwrite
	pa.set_material_override(Vector2i(1,0), mmat2)
	assert_eq(mmat2, pa.get_material_override(Vector2i(0,1)))

	assert_false(mmat1.is_connected("changed", pa._on_material_override_changed))
	assert_true(mmat2.is_connected("changed", pa._on_material_override_changed))


	# Delete
	pa.remove_material_override(Vector2i(1,2))
	assert_eq(1, pa.get_material_overrides().size())
	pa.remove_material_override(Vector2i(0,1))
	assert_eq(0, pa.get_material_overrides().size())

	assert_false(mmat1.is_connected("changed", pa._on_material_override_changed))
	assert_false(mmat2.is_connected("changed", pa._on_material_override_changed))


func test_changed_signals() -> void:
	var points := SS2D_Point_Array.new()
	watch_signals(points)

	points.add_point(Vector2.ZERO)
	assert_signal_emit_count(points, "changed", 1)
	assert_signal_emit_count(points, "update_finished", 1)


	points.begin_update()
	points.add_point(Vector2.ZERO)
	points.add_point(Vector2.ZERO)
	points.add_point(Vector2.ZERO)
	points.end_update()

	assert_signal_emit_count(points, "changed", 4)
	assert_signal_emit_count(points, "update_finished", 2)


func test_helpers() -> void:
	var p_array := SS2D_Point_Array.new()
	var key1 := p_array.add_point(Vector2(0, 0))
	var key2 := p_array.add_point(Vector2(1, 1))
	var key3 := p_array.add_point(Vector2(2, 2))

	assert_eq(p_array.get_edge_keys_for_indices(Vector2i(0, 1)), Vector2i(key1, key2))
	assert_eq(p_array.get_edge_keys_for_indices(Vector2i(1, 2)), Vector2i(key2, key3))


func generate_points() -> PackedVector2Array:
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
