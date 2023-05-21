extends "res://addons/gut/test.gd"

var TEST_TEXTURE: Texture2D = preload("res://tests/unit/test.png")


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
	points_c_clockwise.reverse()

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


# TODO Fix this test and flesh it out
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
#var copy = shape.duplicate()
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
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)
	add_child_autofree(shape)
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)

	var edge_mat = SS2D_Material_Edge.new()
	edge_mat.textures = Array([TEST_TEXTURE], TYPE_OBJECT, "Texture2D", null)

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
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)
	var mappings = SS2D_Shape_Open.get_meta_material_index_mapping(s_m, points, false)

	# Should be 1 edge, as the normal range specified covers the full 360.0 degrees
	assert_eq(mappings.size(), 1, "Should be one EdgeData specified")
	for mapping in mappings:
		assert_not_null(mapping)
		assert_not_null(mapping.object)
		assert_eq(mapping.object.edge_material, edge_mat)


func test_get_edge_meta_materials_many():
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)

	var edge_materials_count = 4
	var edge_materials = []
	var edge_materials_meta: Array[SS2D_Material_Edge_Metadata] = []
	for i in range(0, edge_materials_count, 1):
		var edge_mat = SS2D_Material_Edge.new()
		edge_materials.push_back(edge_mat)
		edge_mat.textures = Array([TEST_TEXTURE], TYPE_OBJECT, "Texture2D", null)

		var edge_mat_meta = SS2D_Material_Edge_Metadata.new()
		edge_materials_meta.push_back(edge_mat_meta)
		var division = 360.0 / edge_materials_count
		var offset = -45
		var normal_range = SS2D_NormalRange.new((division * i) + offset, division)
		edge_mat_meta.edge_material = edge_mat
		edge_mat_meta.normal_range = normal_range
		assert_not_null(edge_mat_meta.edge_material)

	for e in edge_materials_meta:
		print(e.normal_range)

	var s_m := SS2D_Material_Shape.new()
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
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)
	assert_eq(shape.get_vertices().size(), 6)
	assert_eq(s_m.get_all_edge_meta_materials().size(), edge_materials_meta.size())
	var mappings = SS2D_Shape_Open.get_meta_material_index_mapping(s_m, points, false)
	assert_eq(mappings.size(), edge_materials_count, "Expecting %s materials" % edge_materials_count)
	var expected_indicies = [[0, 1, 2], [2, 3], [3, 4], [4, 5]]
	for i in range(0, mappings.size(), 1):
		var mapping = mappings[i]
		assert_eq(expected_indicies[i], mapping.indicies, "Actual indicies match expected?")


var width_params = [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]


func test_build_quad_from_point_width(width = use_parameters(width_params)):
	var shape = SS2D_Shape_Open.new()
	add_child_autofree(shape)

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

	var quad := SS2D_Shape_Open.build_quad_from_two_points(
		pt,
		pt_next,
		TEST_TEXTURE,
		width * TEST_TEXTURE.get_size().y * c_scale,
		false,
		false,
		false,
		false,
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
	var t_idx_1 = get_tessellated_idx_from_point(points, t_points, idx1)
	var t_idx_2 = get_tessellated_idx_from_point(points, t_points, idx2)
	var test_t_idx = int(floor((t_idx_1 + t_idx_2) / 2.0))
	
	# Cache points index maps
	# Map of all tesselated point index to its corresponding vertex index
	var t_point_idx_to_point_idx: Array[int] = []
	# Map of all vertex index to their corresponding tesselated points indices
	var point_idx_to_t_points_idx: Array[Array] = []
	var point_idx = -1
	for t_point_idx in t_points.size():
		var next_point_idx = shape._get_next_point_index_wrap_around(point_idx, points)
		if t_points[t_point_idx] == points[next_point_idx]:
			point_idx = next_point_idx
			point_idx_to_t_points_idx.push_back([])
		
		t_point_idx_to_point_idx.push_back(point_idx)
		point_idx_to_t_points_idx[point_idx].push_back(t_point_idx)
	
	assert_ne(t_idx_1, t_idx_2)
	assert_ne(test_t_idx, t_idx_1)
	assert_ne(test_t_idx, t_idx_2)
	var test_width = shape._get_width_for_tessellated_point(points, test_t_idx, t_point_idx_to_point_idx, point_idx_to_t_points_idx)
	assert_almost_eq(test_width, w_average, 0.1)


func get_clockwise_points() -> PackedVector2Array:
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


func get_tessellated_idx_from_point(
		points: PackedVector2Array, t_points: PackedVector2Array, point_idx: int
) -> int:
	# if idx is 0 or negative
	if point_idx < 1:
		return 0
	if point_idx >= points.size():
		push_error("get_tessellated_idx_from_point:: Out of Bounds point_idx; size is %s; idx is %s" % [points.size(), point_idx])
		return t_points.size() - 1

	var vertex_idx := -1
	var tess_idx := 0
	for i in range(0, t_points.size(), 1):
		tess_idx = i
		var tp: Vector2 = t_points[i]
		var p: Vector2 = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
		if vertex_idx == point_idx:
			break
	return tess_idx
