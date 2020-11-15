extends "res://addons/gut/test.gd"

var TEST_TEXTURE = preload("res://gut/unit/test.png")


class z_sort:
	var z_index: int = 0

	func _init(z: int):
		z_index = z


func test_z_sort():
	var a = [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = SS2D_Shape_Open.sort_by_z_index(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_on_segment():
	var p1 = Vector2(0, 0)
	var p2 = Vector2(-100, 0)
	var p3 = Vector2(100, 0)
	var p4 = Vector2(100, 10)
	var p5 = Vector2(100, 20)
	assert_true(SS2D_Shape_Open.on_segment(p2, p1, p3))
	assert_false(SS2D_Shape_Open.on_segment(p2, p3, p1))
	assert_false(SS2D_Shape_Open.on_segment(p1, p2, p3))
	assert_false(SS2D_Shape_Open.on_segment(p1, p3, p2))
	assert_false(SS2D_Shape_Open.on_segment(p3, p2, p1))
	assert_true(SS2D_Shape_Open.on_segment(p3, p1, p2))

	assert_true(SS2D_Shape_Open.on_segment(p3, p4, p5))
	assert_false(SS2D_Shape_Open.on_segment(p3, p5, p4))

	assert_true(SS2D_Shape_Open.on_segment(p1, p1, p1))


func test_are_points_clockwise():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	var points_clockwise = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise = points_clockwise.duplicate()
	points_c_clockwise.invert()

	shape.add_points(points_clockwise)
	assert_true(shape.are_points_clockwise())

	shape.clear_points()
	shape.add_points(points_c_clockwise)
	assert_false(shape.are_points_clockwise())


func test_curve_duplicate():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	shape.add_point(Vector2(-10, -20))
	var points = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	shape.curve_bake_interval = 35.0
	var curve = shape.get_curve()

	assert_eq(shape.get_point_count(), curve.get_point_count())
	assert_eq(shape.curve_bake_interval, curve.bake_interval)
	shape.curve_bake_interval = 25.0
	assert_ne(shape.curve_bake_interval, curve.bake_interval)

	curve.add_point(points[0])
	assert_ne(shape.get_point_count(), curve.get_point_count())
	shape.set_curve(curve)
	assert_eq(shape.get_point_count(), curve.get_point_count())


func test_tess_point_vertex_relationship():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()

	shape.add_points(points)

	var verts = shape.get_vertices()
	var t_verts = shape.get_tessellated_points()
	assert_eq(points.size(), t_verts.size())

	var control_point_value = Vector2(-16, 0)
	var control_point_vtx_idx = 4

	shape.set_point_in(control_point_vtx_idx, control_point_value)
	shape.set_point_out(control_point_vtx_idx, control_point_value * -1)

	verts = shape.get_vertices()
	t_verts = shape.get_tessellated_points()
	assert_ne(points.size(), t_verts.size())

	var test_idx = 4
	var test_t_idx = shape.get_tessellated_idx_from_point(verts, t_verts, test_idx)
	assert_ne(test_idx, test_t_idx)
	assert_eq(verts[test_idx], t_verts[test_t_idx])
	var new_test_idx = shape.get_vertex_idx_from_tessellated_point(verts, t_verts, test_t_idx)
	assert_eq(test_idx, new_test_idx)

	var results = [
		shape.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx),
		shape.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 1),
		shape.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 2),
		shape.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 3)
	]
	assert_eq(0.0, results[0])
	var message = "Ratio increasing with distance from prev vector"
	for i in range(1, results.size(), 1):
		assert_true(results[i - 1] < results[i], message)

	results[-1] = shape.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx - 1)
	assert_true(results[-1] > results[0], message)


func test_invert_point_order():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()
	var size = points.size()
	var last_idx = size - 1
	var keys = shape.add_points(points)
	shape.set_point_width(keys[0], 5.0)
	assert_eq(points[0], shape.get_point_at_index(0).position)
	assert_eq(points[last_idx], shape.get_point_at_index(last_idx).position)

	assert_eq(1.0, shape.get_point_at_index(last_idx).properties.width)
	assert_eq(5.0, shape.get_point_at_index(0).properties.width)

	shape.invert_point_order()

	assert_eq(5.0, shape.get_point_at_index(last_idx).properties.width)
	assert_eq(1.0, shape.get_point_at_index(0).properties.width)

	assert_eq(points[0], shape.get_point_at_index(last_idx).position)
	assert_eq(points[last_idx], shape.get_point_at_index(0).position)

	assert_eq(points[1], shape.get_point_at_index(last_idx - 1).position)
	assert_eq(points[last_idx - 1], shape.get_point_at_index(1).position)

	assert_eq(points[2], shape.get_point_at_index(last_idx - 2).position)
	assert_eq(points[last_idx - 2], shape.get_point_at_index(2).position)


#func test_duplicate():
#var shape = SS2D_Shape_Open.new()
#add_child_autofree(shape)
#var points = get_clockwise_points()
#shape.add_points(points)
#
#shape.set_point_width(0, 5.0)
#shape.set_point_width(2, 3.0)
#shape.set_point_width(5, 4.0)
#
#shape.set_point_texture_index(0, 1)
#shape.set_point_texture_index(2, 2)
#shape.set_point_texture_index(3, 3)
#shape.set_point_texture_index(5, 5)
#
#shape.set_point_texture_flip(1, true)
#shape.set_point_texture_flip(2, true)
#shape.set_point_texture_flip(4, true)
#
#var copy = shape.duplicate_self()
#add_child_autofree(copy)
#assert_ne(shape.get_curve(), copy.get_curve())
#assert_eq(shape.get_point_count(), copy.get_point_count())
#for i in range(-1, points.size(), 1):
#var s = "Test Point %s: " % i
#assert_eq(shape.get_point_width(i), copy.get_point_width(i), s + "Width")
#assert_eq(shape.get_point_texture_flip(i), copy.get_point_texture_flip(i), s + "Flip")
#assert_eq(
#shape.get_point_texture_index(i), copy.get_point_texture_index(i), s + "Index"
#)


func test_get_edge_meta_materials_one():
	var shape = SS2D_Shape_Open.new()
	assert_eq(shape.material_overrides.size(), 0)
	add_child_autofree(shape)
	assert_eq(shape.material_overrides.size(), 0)

	var edge_mat = SS2D_Material_Edge.new()
	edge_mat.textures = [TEST_TEXTURE]

	var edge_mat_meta = SS2D_Material_Edge_Metadata.new()
	var normal_range = SS2D_NormalRange.new(0, 360.0)
	edge_mat_meta.edge_material = edge_mat
	edge_mat_meta.normal_range = normal_range
	assert_not_null(edge_mat_meta.edge_material)

	var s_m = SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials([edge_mat_meta])
	for e in s_m.get_edge_meta_materials(Vector2(1, 0)):
		assert_not_null(e)
		assert_not_null(e.edge_material)
		assert_eq(e, edge_mat_meta)
		assert_eq(e.edge_material, edge_mat)

	var points = get_clockwise_points()
	shape.add_points(points)
	assert_eq(shape.material_overrides.size(), 0)
	var edge_data = shape.get_edge_material_data(s_m, false)

	# Should be 1 edge, as the normal range specified covers the full 360.0 degrees
	assert_eq(edge_data.size(), 1, "Should be one EdgeData specified")
	for e in edge_data:
		assert_not_null(e)
		assert_not_null(e.meta_material)
		assert_eq(e.meta_material.edge_material, edge_mat)


func test_get_edge_meta_materials_many():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	assert_eq(shape.material_overrides.size(), 0)

	var edge_materials_count = 4
	var edge_materials = []
	var edge_materials_meta = []
	for i in range(0, edge_materials_count, 1):
		var edge_mat = SS2D_Material_Edge.new()
		edge_materials.push_back(edge_mat)
		edge_mat.textures = [TEST_TEXTURE]

		var edge_mat_meta = SS2D_Material_Edge_Metadata.new()
		edge_materials_meta.push_back(edge_mat_meta)
		var division = 360.0 / edge_materials_count
		var offset = -45
		var normal_range = SS2D_NormalRange.new(
			(division * i) + offset, (division * (i + 1)) + offset
		)
		edge_mat_meta.edge_material = edge_mat
		edge_mat_meta.normal_range = normal_range
		assert_not_null(edge_mat_meta.edge_material)

	for e in edge_materials_meta:
		print(e.normal_range)

	var s_m = SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials(edge_materials_meta)
	var n_right = Vector2(1, 0)
	var n_left = Vector2(-1, 0)
	var n_down = Vector2(0, 1)
	var n_up = Vector2(0, -1)
	var normals = [n_right, n_up, n_left, n_down]

	# Ensure that the correct matierlas are given for the correct normals
	for i in range(0, normals.size(), 1):
		var n = normals[i]
		for e in s_m.get_edge_meta_materials(n):
			assert_not_null(e)
			assert_not_null(e.edge_material)
			assert_eq(e, edge_materials_meta[i])
			assert_eq(e.edge_material, edge_materials[i])

	var points = get_square_points()
	shape.add_points(points)
	assert_eq(shape.material_overrides.size(), 0)
	assert_eq(shape.get_vertices().size(), 6)
	assert_eq(s_m.get_all_edge_meta_materials().size(), edge_materials_meta.size())
	var em_data = shape.get_edge_material_data(s_m, false)
	assert_eq(em_data.size(), edge_materials_count)
	var expected_indicies = [[0, 1, 2], [2, 3], [3, 4], [4, 5]]
	for i in range(0, em_data.size(), 1):
		var ed = em_data[i]
		assert_eq(expected_indicies[i], ed.indicies)


var width_params = [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]


func test_build_quad_from_point_width(width = use_parameters(width_params)):
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)

	var edge_mat = SS2D_Material_Edge.new()

	var pt_prev = Vector2(100, 100)
	var pt = Vector2(200, 100)
	var pt_next = Vector2(300, 100)
	var points = [pt_prev, pt, pt_next]

	var c_scale = 1.0
	var c_offset = 0.0
	var c_extends = 0.0
	var delta = points[1] - points[0]
	var normal = Vector2(delta.y, -delta.x).normalized()
	var tex_size = TEST_TEXTURE.get_size()
	var vtx: Vector2 = normal * (tex_size * 0.5)

	var quad = shape._build_quad_from_point(
		pt,
		pt_next,
		TEST_TEXTURE,
		null,
		tex_size,
		width,
		false,
		false,
		false,
		false,
		c_scale,
		c_offset,
		c_extends,
		SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH
	)
	var expected_points = [
		pt + (width * vtx), pt - (width * vtx), pt_next - (width * vtx), pt_next + (width * vtx)
	]
	assert_eq(quad.pt_a, expected_points[0])
	assert_eq(quad.pt_b, expected_points[1])
	assert_eq(quad.pt_c, expected_points[2])
	assert_eq(quad.pt_d, expected_points[3])


func test_get_edge_material_data():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()
	shape.add_points(points)

	# One edge material that applies to all 360 degrees
	var edge_mat = SS2D_Material_Edge.new()
	edge_mat.textures = [TEST_TEXTURE]
	var edge_mat_meta = SS2D_Material_Edge_Metadata.new()
	var normal_range = SS2D_NormalRange.new(0, 360.0)
	edge_mat_meta.edge_material = edge_mat
	edge_mat_meta.normal_range = normal_range
	assert_not_null(edge_mat_meta.edge_material)

	var s_m = SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials([edge_mat_meta])
	# Sanity Check
	for e in s_m.get_edge_meta_materials(Vector2(1, 0)):
		assert_not_null(e)
		assert_not_null(e.edge_material)
		assert_eq(e, edge_mat_meta)
		assert_eq(e.edge_material, edge_mat)

	var edge_material_data: Array = shape.get_edge_material_data(s_m, false)
	assert_eq(edge_material_data.size(), 1, "1 edge should be produced")
	edge_material_data = shape.get_edge_material_data(s_m, true)
	assert_eq(edge_material_data.size(), 1, "1 merged wrap_around edge should be produced")

	# Add Override that shouldn't be rendered
	var override_mat = SS2D_Material_Edge_Metadata.new()
	override_mat.render = false
	var keys = [shape.get_point_key_at_index(1), shape.get_point_key_at_index(2)]
	shape.set_material_override(keys, override_mat)

	edge_material_data = shape.get_edge_material_data(s_m, false)
	assert_eq(edge_material_data.size(), 2, "2 edges should be produced")
	edge_material_data = shape.get_edge_material_data(s_m, true)
	assert_eq(edge_material_data.size(), 1, "1 merged wrap_around edge should be produced")

	# Add Override that shouldn't be rendered
	override_mat = SS2D_Material_Edge_Metadata.new()
	override_mat.render = false
	keys = [shape.get_point_key_at_index(3), shape.get_point_key_at_index(4)]
	shape.set_material_override(keys, override_mat)

	# At this point
	#  - idx 1 and 2 aren't rendered
	#  - idx 2 and 3 are    rendered
	#  - idx 3 and 4 aren't rendered
	# The sequence is
	#   0, 1 | 2, 3 | 4, 5
	edge_material_data = shape.get_edge_material_data(s_m, false)
	assert_eq(edge_material_data.size(), 3, "3 edges should be produced")
	# 0, 1
	assert_eq(edge_material_data[0].indicies.size(), 2)
	# 2, 3
	assert_eq(edge_material_data[1].indicies.size(), 2)
	#  4, 5
	assert_eq(edge_material_data[2].indicies.size(), 2)

	edge_material_data = shape.get_edge_material_data(s_m, true)
	assert_eq(edge_material_data.size(), 2, "2 merged wrap_around edge should be produced")

	# 2, 3
	var em_data_small = edge_material_data[0]
	# 4, 5, 0, 1
	var em_data_large = edge_material_data[1]
	gut.p(em_data_small)
	gut.p(em_data_large)
	assert_eq(em_data_small.indicies.size(), 2)
	assert_eq(em_data_large.indicies.size(), 4)


func test_get_width_for_tessellated_point():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	var points = get_clockwise_points()
	shape.add_points(points)
	var idx1 = 1
	var idx2 = 2
	var k1 = shape.get_point_key_at_index(idx1)
	var k2 = shape.get_point_key_at_index(idx2)
	var w1 = 5.3
	var w2 = 3.15
	var w_average = (w1 + w2) / 2.0
	shape.set_point_width(k1, w1)
	shape.set_point_width(k2, w2)
	var point_in = Vector2(-16, 0)
	var point_out = point_in * -1
	shape.set_point_in(k1, point_in)
	shape.set_point_out(k1, point_out)
	shape.set_point_in(k2, point_in)
	shape.set_point_out(k2, point_out)

	var t_points = shape.get_tessellated_points()
	points = shape.get_vertices()
	var t_idx_1 = shape.get_tessellated_idx_from_point(points, t_points, idx1)
	var t_idx_2 = shape.get_tessellated_idx_from_point(points, t_points, idx2)
	var test_t_idx = int(floor((t_idx_1 + t_idx_2) / 2.0))
	assert_ne(t_idx_1, t_idx_2)
	assert_ne(test_t_idx, t_idx_1)
	assert_ne(test_t_idx, t_idx_2)
	var test_width = shape._get_width_for_tessellated_point(points, t_points, test_t_idx)
	assert_almost_eq(test_width, w_average, 0.1)


func get_clockwise_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]


func get_square_points() -> Array:
	return [
		Vector2(-100, -100),
		Vector2(0, -100),
		Vector2(100, -100),
		Vector2(100, 100),
		Vector2(-100, 100),
		Vector2(-100, -100)
	]
