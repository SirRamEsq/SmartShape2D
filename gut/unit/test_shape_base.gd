extends "res://addons/gut/test.gd"


class z_sort:
	var z_index: int = 0

	func _init(z: int):
		z_index = z


func test_z_sort():
	var a = [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = RMSS2D_Shape_Base.sort_by_z_index(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_are_points_clockwise():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	var points_clockwise = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise = points_clockwise.duplicate()
	points_c_clockwise.invert()

	shape.add_points_to_curve(points_clockwise)
	assert_true(shape.are_points_clockwise())

	shape.clear_points()
	shape.add_points_to_curve(points_c_clockwise)
	assert_false(shape.are_points_clockwise())


func test_curve_duplicate():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	shape.add_point_to_curve(Vector2(-10, -20))
	var points = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	shape.collision_bake_interval = 35.0
	var curve = shape.get_curve()

	assert_eq(shape.get_point_count(), curve.get_point_count())
	assert_eq(shape.collision_bake_interval, curve.bake_interval)
	shape.collision_bake_interval = 25.0
	assert_ne(shape.collision_bake_interval, curve.bake_interval)

	curve.add_point(points[0])
	assert_ne(shape.get_point_count(), curve.get_point_count())
	shape.set_curve(curve)
	assert_eq(shape.get_point_count(), curve.get_point_count())


func test_tess_point_vertex_relationship():
	var s_m = RMSS2D_Shape_Base.new()
	add_child_autofree(s_m)
	var points = get_clockwise_points()

	s_m.add_points_to_curve(points)

	var verts = s_m.get_vertices()
	var t_verts = s_m.get_tessellated_points()
	assert_eq(points.size(), t_verts.size())

	var control_point_value = Vector2(-16, 0)
	var control_point_vtx_idx = 4

	s_m.set_point_in(control_point_vtx_idx, control_point_value)
	s_m.set_point_out(control_point_vtx_idx, control_point_value * -1)

	verts = s_m.get_vertices()
	t_verts = s_m.get_tessellated_points()
	assert_ne(points.size(), t_verts.size())

	var test_idx = 4
	var test_t_idx = s_m.get_tessellated_idx_from_point(verts, t_verts, test_idx)
	assert_ne(test_idx, test_t_idx)
	assert_eq(verts[test_idx], t_verts[test_t_idx])
	var new_test_idx = s_m.get_vertex_idx_from_tessellated_point(verts, t_verts, test_t_idx)
	assert_eq(test_idx, new_test_idx)

	var results = [
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 1),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 2),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 3)
	]
	assert_eq(0.0, results[0])
	var message = "Ratio increasing with distance from prev vector"
	for i in range(1, results.size(), 1):
		assert_true(results[i - 1] < results[i], message)

	results[-1] = s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx - 1)
	assert_true(results[-1] > results[0], message)


func test_invert_point_order():
	var s_m = RMSS2D_Shape_Base.new()
	add_child_autofree(s_m)
	var points = get_clockwise_points()
	var size = points.size()
	var last_idx = size - 1
	s_m.add_points_to_curve(points)
	s_m.set_point_width(0, 5.0)
	assert_eq(points[0], s_m.get_point(0))
	assert_eq(points[last_idx], s_m.get_point(last_idx))

	assert_eq(1.0, s_m.get_point_width(last_idx))
	assert_eq(5.0, s_m.get_point_width(0))

	s_m.invert_point_order()

	assert_eq(5.0, s_m.get_point_width(last_idx))
	assert_eq(1.0, s_m.get_point_width(0))

	assert_eq(points[0], s_m.get_point(last_idx))
	assert_eq(points[last_idx], s_m.get_point(0))

	assert_eq(points[1], s_m.get_point(last_idx - 1))
	assert_eq(points[last_idx - 1], s_m.get_point(1))

	assert_eq(points[2], s_m.get_point(last_idx - 2))
	assert_eq(points[last_idx - 2], s_m.get_point(2))


func test_duplicate():
	var s_m = RMSS2D_Shape_Base.new()
	add_child_autofree(s_m)
	var points = get_clockwise_points()
	s_m.add_points_to_curve(points)

	s_m.set_point_width(0, 5.0)
	s_m.set_point_width(2, 3.0)
	s_m.set_point_width(5, 4.0)

	s_m.set_point_texture_index(0, 1)
	s_m.set_point_texture_index(2, 2)
	s_m.set_point_texture_index(3, 3)
	s_m.set_point_texture_index(5, 5)

	s_m.set_point_texture_flip(1, true)
	s_m.set_point_texture_flip(2, true)
	s_m.set_point_texture_flip(4, true)

	var copy = s_m.duplicate_self()
	add_child_autofree(copy)
	assert_ne(s_m.get_curve(), copy.get_curve())
	assert_eq(s_m.get_point_count(), copy.get_point_count())
	for i in range(-1, points.size(), 1):
		var s = "Test Point %s: " % i
		assert_eq(s_m.get_point_width(i), copy.get_point_width(i), s + "Width")
		assert_eq(s_m.get_point_texture_flip(i), copy.get_point_texture_flip(i), s + "Flip")
		assert_eq(s_m.get_point_texture_index(i), copy.get_point_texture_index(i), s + "Index")


func get_clockwise_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]